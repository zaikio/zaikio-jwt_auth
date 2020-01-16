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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 6.0.1"
  # Authorization tokens
  spec.add_dependency "jwt", ">= 2.2.1"
end
