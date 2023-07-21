require "jwt"
require "oj"
require "active_support/core_ext/integer/time"
require "zaikio/jwt_auth/railtie"
require "zaikio/jwt_auth/configuration"
require "zaikio/jwt_auth/directory_cache"
require "zaikio/jwt_auth/jwk"
require "zaikio/jwt_auth/token_data"
require "zaikio/jwt_auth/rack_middleware"
require "zaikio/jwt_auth/engine"
require "zaikio/jwt_auth/test_helper"

module Zaikio
  module JWTAuth
    DOCS_LINK = "For more information check our docs: https://docs.zaikio.com/guide/oauth/scopes.html".freeze

    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new

      if Zaikio.const_defined?("Webhooks", false)
        Zaikio::Webhooks.on "directory.revoked_access_token", Zaikio::JWTAuth::RevokeAccessTokenJob,
                            perform_now: true
      end

      yield(configuration)
    end

    def self.revoked_jwt?(jti)
      revoked_token_ids.include?(jti)
    end

    def self.revoked_token_ids
      return [] if mocked_jwt_payload

      return configuration.revoked_token_ids if configuration.revoked_token_ids

      result = DirectoryCache.fetch(
        "api/v1/revoked_access_tokens.json",
        expires_after: 60.minutes
      ) || {}

      result.fetch("revoked_token_ids", [])
    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    def self.mocked_jwt_payload
      instance_variable_defined?(:@mocked_jwt_payload) && @mocked_jwt_payload
    end

    def self.mocked_jwt_payload=(payload)
      @mocked_jwt_payload = payload
    end

    HEADER_FORMAT = /\ABearer (.+)\z/.freeze

    def self.extract(authorization_header_string, **options)
      return TokenData.new(Zaikio::JWTAuth.mocked_jwt_payload) if Zaikio::JWTAuth.mocked_jwt_payload

      return if authorization_header_string.blank?

      return unless (token = authorization_header_string[HEADER_FORMAT, 1])

      options.reverse_merge!(algorithms: ["RS256"], jwks: JWK.loader)

      payload, = JWT.decode(token, nil, true, **options)

      TokenData.new(payload)
    end

    def self.decode_jwt(token, **options)
      options = options.reverse_merge(algorithms: ["RS256"], jwks: JWK.loader)
      payload, = JWT.decode(token, nil, true, **options)
      TokenData.new(payload)
    end

    module ClassMethods
      def authorize_by_jwt_subject_type(type = :_not_given_)
        if type != :_not_given_
          @authorize_by_jwt_subject_type = type
        elsif instance_variable_defined?(:@authorize_by_jwt_subject_type)
          @authorize_by_jwt_subject_type
        end
      end

      def authorize_by_jwt_scopes(scopes = nil, options = {})
        @authorize_by_jwt_scopes ||= []

        @authorize_by_jwt_scopes << options.merge(scopes: scopes) if scopes

        @authorize_by_jwt_scopes
      end

      def inherited(child)
        super(child)

        child.instance_variable_set(:@authorize_by_jwt_subject_type, @authorize_by_jwt_subject_type)
        child.instance_variable_set(:@authorize_by_jwt_scopes, @authorize_by_jwt_scopes)
      end
    end

    module InstanceMethods
      def authenticate_by_jwt
        token_data = Zaikio::JWTAuth.extract(request.headers["Authorization"], **jwt_options)
        return render_error("no_jwt_passed", status: :unauthorized) unless token_data

        return if show_error_if_token_is_revoked(token_data)

        return if show_error_if_authorize_by_jwt_subject_type_fails(token_data)

        return if show_error_if_authorize_by_jwt_scopes_fails(token_data)

        send(:after_jwt_auth, token_data) if respond_to?(:after_jwt_auth, true)
      rescue JWT::ExpiredSignature
        render_error("jwt_expired") && (return)
      rescue JWT::DecodeError
        render_error("invalid_jwt") && (return)
      end

      def update_revoked_access_tokens_by_webhook
        return unless %w[directory.revoked_access_token zaikio.revoked_access_token].include?(params[:name])

        DirectoryCache.update("api/v1/revoked_access_tokens.json", expires_after: 60.minutes) do |data|
          data["revoked_token_ids"] << params[:payload][:access_token_id]
          data
        end

        render json: { received: true }
      end

      private

      def find_scope_configurations(scope_configurations)
        scope_configurations.select do |scope_configuration|
          action_matches = action_matches_config?(scope_configuration)

          if action_matches && scope_configuration[:if] && !instance_exec(&scope_configuration[:if])
            false
          elsif action_matches && scope_configuration[:unless] && instance_exec(&scope_configuration[:unless])
            false
          else
            action_matches
          end
        end
      end

      def action_matches_config?(scope_configuration)
        if scope_configuration[:only]
          Array(scope_configuration[:only]).any? { |a| a.to_s == action_name }
        elsif scope_configuration[:except]
          Array(scope_configuration[:except]).none? { |a| a.to_s == action_name }
        else
          true
        end
      end

      def required_scopes(token_data, configuration)
        Array(configuration[:scopes]).flat_map do |allowed_scope|
          %i[r w rw].filter_map do |type|
            app_name = configuration[:app_name] || Zaikio::JWTAuth.configuration.app_name
            full_scope = "#{app_name}.#{allowed_scope}.#{type}"
            if token_data.scope?([allowed_scope], action_name, app_name: app_name, type: configuration[:type],
                                                               scope: [full_scope])
              full_scope
            end
          end
        end
      end

      def show_error_if_authorize_by_jwt_scopes_fails(token_data)
        configurations = find_scope_configurations(self.class.authorize_by_jwt_scopes)

        return if configurations.empty?

        configuration = configurations.find do |scope_configuration|
          token_data.scope_by_configurations?(
            scope_configuration,
            action_name
          )
        end

        return if configuration

        required_scopes = required_scopes(token_data, configuration || configurations.first)

        details = "This endpoint requires one of the following scopes: #{required_scopes.join(', ')} but your " \
        "access token only includes the following scopes: #{token_data.scope.join(', ')} - #{DOCS_LINK}"

        render_error(["unpermitted_scope", details])
      end

      def show_error_if_authorize_by_jwt_subject_type_fails(token_data)
        if !self.class.authorize_by_jwt_subject_type ||
           self.class.authorize_by_jwt_subject_type == token_data.subject_type ||
           (self.class.authorize_by_jwt_subject_type == "Person" && token_data.on_behalf_of_id)
          return
        end

        render_error(["unpermitted_subject", "Expected Subject Type: #{self.class.authorize_by_jwt_subject_type} | "\
        "Subject type from Access Token: #{token_data.subject_type} - #{DOCS_LINK}"])
      end

      def show_error_if_token_is_revoked(token_data)
        return unless Zaikio::JWTAuth.revoked_jwt?(token_data.jti)

        render_error("invalid_jwt")
      end

      def render_error(error, status: :forbidden)
        render(status: status, json: { "errors" => Array(error).compact })
      end

      def jwt_options
        {}
      end
    end
  end
end
