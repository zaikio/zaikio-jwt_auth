module Zaikio
  module JWTAuth
    class Engine < ::Rails::Engine
      isolate_namespace Zaikio::JWTAuth
      engine_name "zaikio_jwt_auth"
      config.generators.api_only = true
    end
  end
end
