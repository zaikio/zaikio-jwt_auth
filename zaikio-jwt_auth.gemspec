$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "zaikio/jwt_auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "zaikio-jwt_auth"
  spec.version     = Zaikio::JWTAuth::VERSION
  spec.authors     = ["Crispy Mountain GmbH"]
  spec.email       = ["js@crispymtn.com"]
  spec.homepage    = "https://www.zaikio.com/"
  spec.summary     = "JWT-Based authentication and authorization with zaikio"
  spec.description = "JWT-Based authentication and authorization with zaikio."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "oj", ">= 3.0.0"
  spec.add_dependency "rails", ">= 6.0.2.2"
  # Authorization tokens
  spec.add_dependency "jwt", ">= 2.2.1"
end
