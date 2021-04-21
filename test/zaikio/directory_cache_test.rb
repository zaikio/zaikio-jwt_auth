require "test_helper"

class Zaikio::JWTAuth::DirectoryCacheTest < ActiveSupport::TestCase
  test "when server responds with a 429 response" do
    stub_request(:get, "http://hub.zaikio.test/foo.json")
      .to_return(status: 429, body: "Retry later", headers: { "Content-Type" => "text/plain" })

    assert_raises(Zaikio::JWTAuth::DirectoryCache::BadResponseError) do
      Zaikio::JWTAuth::DirectoryCache.fetch("foo.json")
    end
  end
end
