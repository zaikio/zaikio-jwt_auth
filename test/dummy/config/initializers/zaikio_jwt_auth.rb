Rails.application.reloader.to_prepare do
  Zaikio::JWTAuth.configure do |config|
    config.environment = :sandbox # or production
    config.app_name = "test_app" # Your Zaikio App-Name
    config.cache = Rails.cache
  end
end
