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

  # Enable caching Hub API responses for e.g. revoked tokens
  config.cache = Rails.cache
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

This gem automatically registers a webhook, if you have properly setup [Zaikio::Webhooks](https://github.com/zaikio/zaikio-webhooks).


### 5. Add more restrictions to your resources:

```rb
class API::ResourcesController < API::ApplicationController
  authorize_by_jwt_subject_type 'Organization'
  authorize_by_jwt_scopes 'resources'
end
```

By convention, `authorize_by_jwt_scopes` automatically maps all CRUD actions in a controller. Requests for `show` and `index` with a read or read_write scope are allowed. All other actions like `create`, `update` and `destroy` are accepted if the scope is a write or read_write scope. Therefore it is strongly recommended to always create standard Rails resources. If a custom action is required, you will need to authorize yourself using the `after_jwt_auth`.

Both of these behaviours are automatically inherited by child classes, for example:

```ruby
class API::ChildController < API::ResourcesController
end

API::ChildController.authorize_by_jwt_subject_type
#=> "Organization"
```

You can always override the behaviour in children if needed:

```ruby
class API::ChildController < API::ResourcesController
  authorize_by_jwt_subject_type nil
end
```

#### Modifying required scopes
If you nonetheless want to change the required scopes for CRUD routes, you can use the `type` option which accepts the following values: `:read`, `:write`, `:read_write`

```rb
class API::ResourcesController < API::ApplicationController
  # Require a write or read_write scope on the index route
  authorize_by_jwt_scopes 'resources', only: :index, type: :write
end
```

#### Using custom actions
You can also specify authorization for custom actions. When doing so the `type` option is required.

```rb
class API::ResourcesController < API::ApplicationController
  # Require the index use to have a write or read_write scope
  authorize_by_jwt_scopes 'resources', only: :my_custom_route, type: :write
end
```

### 6. Optionally, if you are using SSO: Check revoked tokens

Additionally, the API provides a method called `revoked_jwt?` which expects the `jti` of the JWT.

```rb
Zaikio::JWTAuth.revoked_jwt?('jti-of-token') # returns true if token was revoked
```

### 7. Optionally, use the test helper module to mock JWTs in your minitests

```rb
# in your test_helper.rb
class ActiveSupport::TestCase
  # ...
  include Zaikio::JWTAuth::TestHelper
  # ...
end

# in your integration tests you can use:
class ResourcesControllerTest < ActionDispatch::IntegrationTest
  def setup
    mock_jwt(sub: 'Organization/123', scope: ['directory.organization.r'])
  end

  test "do a request with a mocked jwt" do
    get resources_path
    # test the actual business logic
  end
end
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

### Usage outside a Rails controller

If you need to access a JWT outside the normal Rails controllers (e.g. in a Rack
middleware), there's a static helper method `.extract` which you can use:

```ruby
class MyRackMiddleware < Rack::Middleware
  def call(env)
    token = Zaikio::JWTAuth.extract(env["HTTP_AUTHORIZATION"])
    puts token.subject_type #=> "Organization"
    ...
```

This function expects to receive the string in the format `"Bearer $token"`. If the JWT is
invalid, expired, or has some other fundamental issues, the JWT library may throw
[additional errors](https://github.com/jwt/ruby-jwt/blob/v2.2.2/lib/jwt/error.rb), and you
should be prepared to handle these, for example:

```ruby
def call(env)
  token = Zaikio::JWTAuth.extract("definitely.not.jwt")
rescue JWT::DecodeError, JWT::ExpiredSignature
  [401, {}, ["Unauthorized"]]
end
```

### Using a different cache backend

This client supports any implementation of
[`ActiveSupport::Cache::Store`](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html),
but you can also write your own client that supports these methods: `#read(key)`,
`#write(key, value)`, `#delete(key)`

### Pass custom options to JWT auth

In some cases you want to add custom options to the JWT check. For example you want to allow expired JWTs when revoking access tokens.

```rb
class API::RevokedAccessTokensController < API::ApplicationController
  def jwt_options
    { verify_expiration: false }
  end
end
```

## Contributing

**Make sure you have the dummy app running locally to validate your changes.**

- Make your changes and submit a pull request for them
- Make sure to update `CHANGELOG.md`

To release a new version of the gem:
- Update the version in `lib/zaikio/jwt_auth/version.rb`
- Update `CHANGELOG.md` to include the new version and its release date
- Commit and push your changes
- Create a [new release on GitHub](https://github.com/zaikio/zaikio-jwt_auth/releases/new)
- CircleCI will build the Gem package and push it Rubygems for you
