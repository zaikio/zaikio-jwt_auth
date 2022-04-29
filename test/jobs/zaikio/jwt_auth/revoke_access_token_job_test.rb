require "test_helper"

class Zaikio::JWTAuth::RevokeAccessTokenJobTest < ActiveSupport::TestCase
  def setup
    Zaikio::JWTAuth.configure do |config|
      config.environment = :test
      config.app_name = "test_app"
      config.cache = ActiveSupport::Cache::RedisCacheStore.new
    end

    stub_requests
  end

  def job
    Zaikio::JWTAuth::RevokeAccessTokenJob.new
  end

  test "adds token to revoked ones" do
    event = OpenStruct.new(payload: { "access_token_id" => "my-webhook-token" })
    job.perform(event)
    cache = Zaikio::JWTAuth::DirectoryCache.fetch("api/v1/revoked_access_tokens.json")
    assert_equal "my-webhook-token", cache["revoked_token_ids"].last
  end
end
