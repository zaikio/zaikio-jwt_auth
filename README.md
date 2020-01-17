# Zaikio::JWTAuth

Gem for JWT-Based authentication and authorization with zaikio.

## Usage

## Installation

Add this line to your application's Gemfile:

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

Configure the gem:

```rb
# config/initializers/zaikio_jwt_auth.rb

Zaikio::JWTAuth.configure do |config|
  config.environment = :sandbox # or production
  config.app_name = "test_app" # Your Zaikio App-Name
  config.redis = Redis.new
end
```

Extend your API application controller:

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

Add more restrictions to your resources:

```rb
class API::ResourcesController < API::ApplicationController
  authorize_by_jwt_subject_type 'Organization'
  authorize_by_jwt_scopes 'resources'
end
```
