require "logger"

module Zaikio
  module JWTAuth
    class Configuration
      HOSTS = {
        development: "http://directory.zaikio.test",
        test: "http://directory.zaikio.test",
        staging: "https://directory.staging.zaikio.com",
        sandbox: "https://directory.sandbox.zaikio.com",
        production: "https://directory.zaikio.com"
      }.freeze

      attr_accessor :app_name
      attr_accessor :redis, :host
      attr_reader :environment
      attr_writer :logger, :blacklisted_token_ids, :keys

      def initialize
        @environment = :sandbox
        @blacklisted_token_ids = nil
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def environment=(env)
        @environment = env.to_sym
        @host = host_for(environment)
      end

      def keys
        @keys.is_a?(Proc) ? @keys.call : @keys
      end

      def blacklisted_token_ids
        @blacklisted_token_ids.is_a?(Proc) ? @blacklisted_token_ids.call : @blacklisted_token_ids
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
