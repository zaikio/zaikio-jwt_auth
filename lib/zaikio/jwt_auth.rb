require "jwt"
require "zaikio/jwt_auth/railtie"
require "zaikio/jwt_auth/configuration"
require "zaikio/jwt_auth/directory_cache"
require "zaikio/jwt_auth/jwk"
require "zaikio/jwt_auth/token_data"

module Zaikio
  module JWTAuth
    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def authorize_by_jwt_subject_type(type = nil)
        @authorize_by_jwt_subject_type ||= type
      end

      def authorize_by_jwt_scopes(scopes = nil)
        @authorize_by_jwt_scopes ||= scopes
      end
    end

    module InstanceMethods
      def authenticate_by_jwt
        unless jwt_from_auth_header
          render(status: :unauthorized, plain: "Please authenticate via Zaikio JWT") && return
        end

        token_data = TokenData.new(jwt_payload)

        return if show_error_if_token_is_blacklisted(token_data)

        return if show_error_if_authorize_by_jwt_subject_type_fails(token_data)

        return if show_error_if_authorize_by_jwt_scopes_fails(token_data)

        send(:after_jwt_auth, token_data) if respond_to?(:after_jwt_auth)
      rescue JWT::ExpiredSignature
        render(status: :forbidden, plain: "JWT expired") && (return)
      rescue JWT::DecodeError
        render(status: :forbidden, plain: "Invalid JWT") && (return)
      end

      private

      def jwt_from_auth_header
        auth_header = request.headers["Authorization"]
        auth_header.split("Bearer ").last if /Bearer/.match?(auth_header)
      end

      def jwt_payload
        payload, = JWT.decode(jwt_from_auth_header, nil, true, algorithms: ["RS256"], jwks: JWK.loader)

        payload
      end

      def show_error_if_authorize_by_jwt_scopes_fails(token_data)
        if !self.class.authorize_by_jwt_scopes || token_data.scope?(self.class.authorize_by_jwt_scopes, action_name)
          return
        end

        render(status: :forbidden, plain: "Invalid scope")
      end

      def show_error_if_authorize_by_jwt_subject_type_fails(token_data)
        if !self.class.authorize_by_jwt_subject_type ||
           self.class.authorize_by_jwt_subject_type == token_data.subject_type
          return
        end

        render(status: :forbidden, plain: "Unallowed subject type")
      end

      def show_error_if_token_is_blacklisted(token_data)
        return unless blacklisted_token_ids.include?(token_data.jti)

        render(status: :forbidden, plain: "Invalid token")
      end

      def blacklisted_token_ids
        if Zaikio::JWTAuth.configuration.blacklisted_token_ids
          return Zaikio::JWTAuth.configuration.blacklisted_token_ids
        end

        DirectoryCache.fetch("api/v1/blacklisted_token_ids.json", expires_after: 5.minutes)["blacklisted_token_ids"]
      end
    end
  end
end
