module Zaikio
  module JWTAuth
    class RackMiddleware
      AUDIENCE = "zaikio.jwt.audience".freeze
      SUBJECT  = "zaikio.jwt.subject".freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        token_data = begin
          Zaikio::JWTAuth.extract(env["HTTP_AUTHORIZATION"])
        rescue JWT::ExpiredSignature, JWT::DecodeError
          nil
        end

        if token_data
          env[AUDIENCE] = token_data.audience || :personal_token
          env[SUBJECT] = token_data.subject
        end

        @app.call(env)
      end
    end
  end
end
