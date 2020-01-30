# Zaikio::JWTAuth

Gem for JWT-Based authentication and authorization with zaikio.

## Usage

## Installation

1. Add this line to your application's Gemfile:

```ruby
gem 'zaikio-jwt_auth'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install zaikio-jwt_auth
```

2. Configure the gem:

```rb
# config/initializers/zaikio_jwt_auth.rb

Zaikio::JWTAuth.configure do |config|
  config.environment = :sandbox # or production
  config.app_name = "test_app" # Your Zaikio App-Name
  config.redis = Redis.new
end
```

3. Extend your API application controller:

```rb
class API::ApplicationController < ActionController::Base
  include Zaikio::JWTAuth

  before_action :authenticate_by_jwt

  def after_jwt_auth(token_data)
    klass = token_data.subject_type == 'Organization' ? Organization : Person
    Current.scope = klass.find(token_data.subject_id)
  end
end
```

4. Update Revoked Access Tokens by Webhook

```rb
# ENV['ZAIKIO_SHARED_SECRET'] needs to be defined first, you can find it on your
# app details page in zaikio. Fore more help read:
# https://docs.zaikio.com/guide/loom/receiving-events.html
class WebhooksController < ActionController::Base
  include Zaikio::JWTAuth

  before_action :verify_signature
  before_action :update_blacklisted_access_tokens_by_webhook

  def create
    case params[:name]
      # Manage other events
    end
  end

  private

  def verify_signature
    # Read More: https://docs.zaikio.com/guide/loom/receiving-events.html
    unless ActiveSupport::SecurityUtils.secure_compare(
      OpenSSL::HMAC.hexdigest("SHA256", "shared-secret", request.body.read),
      request.headers["X-Loom-Signature"]
    )
      render status: :unauthorized, json: { errors: ["invalid_signature"] }
    end
  end
end
```


5. Add more restrictions to your resources:

```rb
class API::ResourcesController < API::ApplicationController
  authorize_by_jwt_subject_type 'Organization'
  authorize_by_jwt_scopes 'resources'
end
```
