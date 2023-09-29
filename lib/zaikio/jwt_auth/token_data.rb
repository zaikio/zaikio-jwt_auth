module Zaikio
  module JWTAuth
    class TokenData
      def self.subject_format
        %r{^((\w+)/((\w|-)+)>)?(\w+)/((\w|-)+)$}
      end

      def self.actions_by_permission
        {
          "r" => %w[show index],
          "w" => %w[update create destroy],
          "rw" => %w[show index update create destroy]
        }.freeze
      end

      def self.permissions_by_type
        {
          read: %w[r rw],
          write: %w[rw w],
          read_write: %w[r rw w]
        }
      end

      def initialize(payload, token: nil)
        @payload = payload
        @token = token
      end

      def to_s
        @token
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

      def expires_at
        Time.zone.at(@payload["exp"]).to_datetime
      end

      # scope_options is an array of objects with:
      # scope, app_name (optional), except/only (array, optional), type (read, write, readwrite)
      def scope_by_configurations?(configuration, action_name)
        return true unless configuration

        scope?(configuration[:scopes], action_name, app_name: configuration[:app_name], type: configuration[:type])
      end

      def scope?(allowed_scopes, action_name, app_name: nil, type: nil, scope: nil) # rubocop:disable Metrics/AbcSize
        app_name ||= Zaikio::JWTAuth.configuration.app_name
        scope ||= self.scope
        Array(allowed_scopes).map(&:to_s).any? do |allowed_scope|
          scope.any? do |s|
            parts = s.split(".")
            parts[0] == app_name &&
              parts[1] == allowed_scope &&
              action_permitted?(action_name, parts[2], type: type)
          end
        end
      end

      def subject_id
        subject_match[6]
      end

      def subject_type
        subject_match[5]
      end

      def subject
        "#{subject_type}/#{subject_id}"
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

      def action_permitted?(action_name, permission, type: nil)
        if type
          return false unless self.class.permissions_by_type.key?(type)

          self.class.permissions_by_type[type].include?(permission)
        else
          self.class.actions_by_permission[permission].include?(action_name)
        end
      end
    end
  end
end
