module Zaikio
  module JWTAuth
    class TokenData
      def self.subject_format
        %r{^((\w+)/((\w|-)+)\>)?(\w+)/((\w|-)+)$}
      end

      def self.actions_by_permission
        {
          "r" => %w[show index],
          "w" => %w[update create destroy],
          "rw" => %w[show index update create destroy]
        }.freeze
      end

      def initialize(payload)
        @payload = payload
      end

      def audience
        audiences.first
      end

      def audiences
        @payload["aud"] || []
      end

      def scope
        @payload["scope"]
      end

      def jti
        @payload["jti"]
      end

      def scope?(allowed_scopes, action_name, app_name = nil)
        app_name ||= Zaikio::JWTAuth.configuration.app_name
        Array(allowed_scopes).map(&:to_s).any? do |allowed_scope|
          scope.any? do |s|
            parts = s.split(".")
            parts[0] == app_name &&
              parts[1] == allowed_scope &&
              action_in_permission?(action_name, parts[2])
          end
        end
      end

      def subject_id
        subject_match[6]
      end

      def subject_type
        subject_match[5]
      end

      def on_behalf_of_id
        subject_match[3]
      end

      def on_behalf_of_type
        subject_match[2]
      end

      def subject_match
        self.class.subject_format.match(@payload["sub"]) || []
      end

      private

      def action_in_permission?(action_name, permission)
        self.class.actions_by_permission[permission].include?(action_name)
      end
    end
  end
end
