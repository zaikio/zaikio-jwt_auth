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

      # scope_options is an array of objects with:
      # scope, app_name (optional), except/only (array, optional)
      def scope_by_configurations?(scope_configurations, action_name, context)
        configuration = scope_configurations.find do |scope_configuration|
          action_matches = action_matches_config?(scope_configuration, action_name)

          if action_matches && scope_configuration[:if] && !context.instance_exec(&scope_configuration[:if])
            false
          elsif action_matches && scope_configuration[:unless] && context.instance_exec(&scope_configuration[:unless])
            false
          else
            action_matches
          end
        end

        return true unless configuration

        scope?(configuration[:scopes], action_name, configuration[:app_name])
      end

      def action_matches_config?(scope_configuration, action_name)
        if scope_configuration[:only]
          Array(scope_configuration[:only]).any? { |a| a.to_s == action_name }
        elsif scope_configuration[:except]
          Array(scope_configuration[:except]).none? { |a| a.to_s == action_name }
        else
          true
        end
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
