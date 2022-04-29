require "test_helper"

module Zaikio::JWTAuth
  class DirectoryCacheTest < ActiveSupport::TestCase
    def setup
      Zaikio::JWTAuth.configure do |config|
        config.environment = :test
        config.cache = ActiveSupport::Cache::RedisCacheStore.new
      end
    end

    test "when server responds with a 429 response, we return existing set and enqueue job to update" do
      # First, fill the cache with a successful response
      stub_request(:get, "http://hub.zaikio.test/foo.json")
        .to_return(status: 200,
                   headers: { "Content-Type" => "application/json" }, body: {
                     revoked_token_ids: %w[old-token]
                   }.to_json)
        .then.to_return(status: 429, body: "Retry later", headers: { "Content-Type" => "text/plain" })

      assert_equal(
        { "revoked_token_ids" => %w[old-token] },
        DirectoryCache.fetch("foo.json", invalidate: true)
      )

      # Now pretend the Hub has become unavailable
      stub_request(:get, "http://hub.zaikio.test/foo.json")
        .to_return(status: 429, body: "Retry later", headers: { "Content-Type" => "text/plain" })

      DirectoryCache::UpdateJob.expects(:set).with(wait: 10.seconds).returns(DirectoryCache::UpdateJob)
      DirectoryCache::UpdateJob.expects(:perform_later).with("foo.json")

      assert_equal(
        { "revoked_token_ids" => %w[old-token] },
        DirectoryCache.fetch("foo.json", invalidate: true)
      )
    end

    test "UpdateJob runs the fetch command" do
      stub_request(:get, "http://hub.zaikio.test/foo.json")
        .to_return(status: 200,
                   headers: { "Content-Type" => "application/json" }, body: {
                     revoked_token_ids: %w[old-token]
                   }.to_json)
        .then.to_return(status: 429, body: "Retry later", headers: { "Content-Type" => "text/plain" })

      assert DirectoryCache::UpdateJob.new.perform("foo.json")
    end
  end
end
