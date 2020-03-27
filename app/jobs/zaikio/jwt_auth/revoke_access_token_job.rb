module Zaikio
  module JWTAuth
    class RevokeAccessTokenJob < ApplicationJob
      def perform(event)
        DirectoryCache.update("api/v1/blacklisted_access_tokens.json", expires_after: 60.minutes) do |data|
          data["blacklisted_token_ids"] << event.payload["access_token_id"]
          data
        end
      end
    end
  end
end
