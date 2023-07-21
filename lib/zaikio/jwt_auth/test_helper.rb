module Zaikio
  module JWTAuth
    module TestHelper
      def self.jwk
        @jwk ||= JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), { kid: "test-kid", use: "sig", alg: "RS256" })
      end

      def self.jwk_set
        @jwk_set ||= JWT::JWK::Set.new(jwk).export
      end



      def after_teardown
        Zaikio::JWTAuth.mocked_jwt_payload = nil
        super
      end

      def mock_jwt(params)
        Zaikio::JWTAuth.mocked_jwt_payload = generate_token_payload(params)
      end

      def issue_mock_jwt_token(params)
        JWT.encode(
          generate_token_payload(params),
          jwk.signing_key,
          jwk[:alg],
          kid: jwk[:kid]
        )
      end

      def generate_token_payload(params)
        {
          iss: "ZAI",
          sub: nil,
          aud: %w[test_app],
          jti: SecureRandom.uuid,
          nbf: Time.now.to_i,
          exp: 1.hour.from_now.to_i,
          jku: "http://hub.zaikio.test/api/v1/jwt_public_keys.json",
          scope: []
        }.merge(params).stringify_keys
      end

      def jwk = Zaikio::JWTAuth::TestHelper.jwk
    end
  end
end
