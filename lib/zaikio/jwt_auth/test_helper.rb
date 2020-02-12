module Zaikio
  module JWTAuth
    module TestHelper
      def after_setup
        Zaikio::JWTAuth.mocked_jwt_payload = nil
        super
      end

      def mock_jwt(extra_payload)
        Zaikio::JWTAuth.mocked_jwt_payload = {
          iss: "ZAI",
          sub: nil,
          aud: %w[test_app],
          jti: "unique-access-token-id",
          nbf: Time.now.to_i,
          exp: 1.hour.from_now.to_i,
          jku: "http://directory.zaikio.test/api/v1/jwt_public_keys.json",
          scope: []
        }.merge(extra_payload).stringify_keys
      end
    end
  end
end
