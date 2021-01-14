require "logger"

module Zaikio
  module JWTAuth
    class Configuration
      HOSTS = {
        development: "http://hub.zaikio.test",
        test: "http://hub.zaikio.test",
        staging: "https://hub.staging.zaikio.com",
        sandbox: "https://hub.sandbox.zaikio.com",
        production: "https://hub.zaikio.com"
      }.freeze

      attr_accessor :app_name, :redis, :host
      attr_reader :environment
      attr_writer :logger, :revoked_token_ids, :keys

      def initialize
        @environment = :sandbox
        @revoked_token_ids = nil
        @keys = nil
      end

      def logger
        @logger ||= Logger.new($stdout)
      end

      def environment=(env)
        @environment = env.to_sym
        @host = host_for(environment)
      end

      def keys
        @keys.is_a?(Proc) ? @keys.call : @keys
      end

      def revoked_token_ids
        @revoked_token_ids.is_a?(Proc) ? @revoked_token_ids.call : @revoked_token_ids
      end

      private

      def host_for(environment)
        HOSTS.fetch(environment) do
          raise StandardError.new, "Invalid Zaikio::JWTAuth environment '#{environment}'"
        end
      end
    end
  end
end
