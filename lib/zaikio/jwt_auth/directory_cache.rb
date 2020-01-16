require "net/http"
require "json"
require "logger"

module Zaikio
  module JWTAuth
    class DirectoryCache
      class << self
        def fetch(directory_path, options = {})
          cache = Zaikio::JWTAuth.configuration.redis.get("zaikio::jwt_auth::#{directory_path}")

          json = JSON.parse(cache) if cache

          if !cache || options[:invalidate] || cache_expired?(json, options[:expires_after])
            return reload(directory_path)
          end

          json["data"]
        end

        private

        def cache_expired?(json, expires_after)
          DateTime.strptime(json["fetched_at"].to_s, "%s") < Time.now.utc - (expires_after || 1.hour)
        end

        def reload(directory_path)
          retries = 0

          begin
            data = fetch_from_directory(directory_path)
            Zaikio::JWTAuth.configuration.redis.set("zaikio::jwt_auth::#{directory_path}", {
              fetched_at: Time.now.to_i,
              data: data
            }.to_json)

            data
          rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
            raise unless (retries += 1) <= 3

            Zaikio::JWTAuth.configuration.logger.log("Timeout (#{e}), retrying in 1 second...")
            sleep(1)
            retry
          end
        end

        def fetch_from_directory(directory_path)
          uri = URI("#{Zaikio::JWTAuth.configuration.host}/#{directory_path}")
          JSON.parse(Net::HTTP.get(uri))
        end
      end
    end
  end
end
