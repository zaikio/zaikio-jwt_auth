require "net/http"
require "json"
require "logger"

module Zaikio
  module JWTAuth
    class DirectoryCache
      class UpdateJob < ::ActiveJob::Base
        def perform(directory_path)
          DirectoryCache.fetch(directory_path)
          true # This job will always re-queue until it succeeds.
        end
      end

      BadResponseError = Class.new(StandardError)

      class << self
        def fetch(directory_path, options = {})
          cache = Zaikio::JWTAuth.configuration.redis.get("zaikio::jwt_auth::#{directory_path}")

          json = Oj.load(cache) if cache

          if !cache || options[:invalidate] || cache_expired?(json, options[:expires_after])
            new_values = reload_or_enqueue(directory_path)
            return new_values || json["data"]
          end

          json["data"]
        end

        def update(directory_path, options = {})
          data = fetch(directory_path, options)
          data = yield(data)
          Zaikio::JWTAuth.configuration.redis.set("zaikio::jwt_auth::#{directory_path}", {
            fetched_at: Time.now.to_i,
            data: data
          }.to_json)
        end

        def reset(directory_path)
          Zaikio::JWTAuth.configuration.redis.del("zaikio::jwt_auth::#{directory_path}")
        end

        private

        def cache_expired?(json, expires_after)
          DateTime.strptime(json["fetched_at"].to_s, "%s") < Time.now.utc - (expires_after || 1.hour)
        end

        def reload_or_enqueue(directory_path)
          data = fetch_from_directory(directory_path)
          Zaikio::JWTAuth.configuration.redis.set("zaikio::jwt_auth::#{directory_path}", {
            fetched_at: Time.now.to_i,
            data: data
          }.to_json)

          data
        rescue Errno::ECONNREFUSED, Net::ReadTimeout, BadResponseError
          Zaikio::JWTAuth.configuration.logger
                         .info("Error updating DirectoryCache(#{directory_path}), enqueueing job to update")
          UpdateJob.set(wait: 10.seconds).perform_later(directory_path)
          nil
        end

        def fetch_from_directory(directory_path)
          response = make_http_request(directory_path)

          raise BadResponseError unless (200..299).cover?(response.code.to_i)
          raise BadResponseError unless response["content-type"].to_s.include?("application/json")

          Oj.load(response.body)
        end

        def make_http_request(directory_path)
          uri = URI("#{Zaikio::JWTAuth.configuration.host}/#{directory_path}")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          http.request(Net::HTTP::Get.new(uri.request_uri))
        end
      end
    end
  end
end
