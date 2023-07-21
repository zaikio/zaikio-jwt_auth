require "net/http"
require "json"
require "logger"

module Zaikio
  module JWTAuth
    class JWK
      CACHE_EXPIRES_AFTER = 1.hour.freeze

      class << self
        def loader
          lambda do |options|
            return TestHelper.jwk_set if Rails.env.test?

            reload_keys if options[:invalidate]

            {
              keys: keys.map do |key_data|
                JWT::JWK.import(key_data.with_indifferent_access).export
              end
            }
          end
        end

        private

        def reload_keys
          return if Zaikio::JWTAuth.configuration.keys

          fetch_from_cache(invalidate: true)
        end

        def keys
          return Zaikio::JWTAuth.configuration.keys if Zaikio::JWTAuth.configuration.keys

          fetch_from_cache.fetch("keys")
        end

        def fetch_from_cache(options = {})
          DirectoryCache.fetch("api/v1/jwt_public_keys.json", {
            expires_after: CACHE_EXPIRES_AFTER
          }.merge(options))
        end
      end
    end
  end
end
