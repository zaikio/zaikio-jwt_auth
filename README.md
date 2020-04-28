# Zaikio::JWTAuth

Gem for JWT-Based authentication and authorization with zaikio.

## Installation

### 1. Add this line to your application's Gemfile:

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

### 2. Configure the gem:

```rb
# config/initializers/zaikio_jwt_auth.rb

Zaikio::JWTAuth.configure do |config|
  config.environment = :sandbox # or production
  config.app_name = "test_app" # Your Zaikio App-Name
  config.redis = Redis.new
end
```

### 3. Extend your API application controller:

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

### 4. Update Revoked Access Tokens by Webhook

This gem automatically registers a webhook, if you have properly setup [Zaikio::Webhooks](https://github.com/crispymtn/zaikio-webhooks).


### 5. Add more restrictions to your resources:

```rb
class API::ResourcesController < API::ApplicationController
  authorize_by_jwt_subject_type 'Organization'
  authorize_by_jwt_scopes 'resources'
end
```

By convention, `authorize_by_jwt_scopes` automatically maps all CRUD actions in a controller. Requests for `show` and `index` with a read or read_write scope are allowed. All other actions like `create`, `update` and `destroy` are accepted if the scope is a write or read_write scope. Therefore it is strongly recommended to always create standard Rails resources. If a custom action is required, you will need to authorize yourself using the `after_jwt_auth`.

### 6. Optionally, if you are using SSO: Check revoked tokens

Additionally, the API provides a method called `revoked_jwt?` which expects the `jti` of the JWT.

```rb
Zaikio::JWTAuth.revoked_jwt?('jti-of-token') # returns true if token was revoked
```

### 7. Optionally, use the test helper module to mock JWTs in your minitests

```rb
# in your test_helper.rb
include Zaikio::JWTAuth::TestHelper

# in your tests you can use:
mock_jwt(sub: 'Organization/123', scope: ['directory.organization.r'])
```

## Advanced

### `only` and `except`

Similar to Rails' controller callbacks, `authorize_by_jwt_scopes` can also be passed a list of actions:

```rb
class API::ResourcesController < API::ApplicationController
  authorize_by_jwt_subject_type 'Organization'
  authorize_by_jwt_scopes 'resources', except: :destroy
  authorize_by_jwt_scopes 'remove_resources', only: [:destroy]
end
```


### `if` and `unless`

Similar to Rails' controller callbacks, `authorize_by_jwt_scopes` can also handle a lambda in the context of the controller to request parameters.

```rb
class API::ResourcesController < API::ApplicationController
  authorize_by_jwt_scopes 'resources', unless: -> { params[:skip] == '1' }
end
```
