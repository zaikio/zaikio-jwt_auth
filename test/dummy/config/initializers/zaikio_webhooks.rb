Zaikio::Webhooks.configure do |config|
  config.register_client :my_app do |my_app|
    my_app.shared_secret = "test-secret"
  end
end
