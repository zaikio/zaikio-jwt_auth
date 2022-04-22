require "jwt"
require "oj"
require "active_support/core_ext/integer/time"
require "zaikio/jwt_auth/railtie"
require "zaikio/jwt_auth/configuration"
require "zaikio/jwt_auth/directory_cache"
require "zaikio/jwt_auth/jwk"
require "zaikio/jwt_auth/token_data"
require "zaikio/jwt_auth/engine"
require "zaikio/jwt_auth/test_helper"

module Zaikio
  module JWTAuth
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

      configuration.revoked_token_ids || DirectoryCache.fetch(
        "api/v1/revoked_access_tokens.json",
        expires_after: 60.minutes
      )["revoked_token_ids"]
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

    def self.extract(authorization_header_string)
      return TokenData.new(Zaikio::JWTAuth.mocked_jwt_payload) if Zaikio::JWTAuth.mocked_jwt_payload

      return if authorization_header_string.blank?

      return unless (token = authorization_header_string[HEADER_FORMAT, 1])

      payload, = JWT.decode(token, nil, true, algorithms: ["RS256"], jwks: JWK.loader)

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
        token_data = Zaikio::JWTAuth.extract(request.headers["Authorization"])
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
        return unless params[:name] == "directory.revoked_access_token"

        DirectoryCache.update("api/v1/revoked_access_tokens.json", expires_after: 60.minutes) do |data|
          data["revoked_token_ids"] << params[:payload][:access_token_id]
          data
        end

        render json: { received: true }
      end

      private

      def show_error_if_authorize_by_jwt_scopes_fails(token_data)
        return if token_data.scope_by_configurations?(
          self.class.authorize_by_jwt_scopes,
          action_name,
          self
        )

        render_error("unpermitted_scope")
      end

      def show_error_if_authorize_by_jwt_subject_type_fails(token_data)
        if !self.class.authorize_by_jwt_subject_type ||
           self.class.authorize_by_jwt_subject_type == token_data.subject_type
          return
        end

        render_error("unpermitted_subject")
      end

      def show_error_if_token_is_revoked(token_data)
        return unless Zaikio::JWTAuth.revoked_jwt?(token_data.jti)

        render_error("invalid_jwt")
      end

      def render_error(error, status: :forbidden)
        render(status: status, json: { "errors" => [error] })
      end
    end
  end
end
