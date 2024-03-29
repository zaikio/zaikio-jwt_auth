require "test_helper"

class TestHelperOrganization
  def self.find(id)
    new(id)
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end
end

class TestHelperResourcesController < ApplicationController
  include Zaikio::JWTAuth

  before_action :authenticate_by_jwt

  # can also be called later
  authorize_by_jwt_subject_type "Organization"
  authorize_by_jwt_scopes :resources

  def index
    render plain: "hello"
  end

  def create
    render plain: "hello"
  end

  def after_jwt_auth(token_data)
    klass = token_data.subject_type == "Organization" ? TestHelperOrganization : TestHelperPerson
    @scope = klass.find(token_data.subject_id) # Current.scope
    @audience = token_data.audience
    @token = token_data.to_s
  end
end

class TestHelperTest < ActionDispatch::IntegrationTest
  def setup
    Zaikio::JWTAuth.configure do |config|
      config.environment = :test
      config.app_name = "test_app"
      config.cache = ActiveSupport::Cache::RedisCacheStore.new
    end

    Rails.application.routes.draw do
      resources :resources, controller: "test_helper_resources"
    end
  end

  test "unauthorized if no token was passed" do
    get "/resources"
    assert_response :unauthorized
    assert_equal({ "errors" => ["no_jwt_passed"] }.to_json, response.body)
  end

  test "forbidden if invalid subject type" do
    token = mock_jwt(sub: "Person/abc")
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["unpermitted_subject", "Expected Subject Type: Organization | Subject type from "\
    "Access Token: Person - For more information check our docs: "\
    "https://docs.zaikio.com/guide/oauth/scopes.html"] }.to_json, response.body)
  end

  test "forbidden if scope does not exist" do
    token = mock_jwt(scope: ["directory.person.r", "test_app.some.rw"], sub: "Organization/123")
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["unpermitted_scope", "This endpoint requires one of the following scopes: "\
    "test_app.resources.r, test_app.resources.rw but your access token only includes the following scopes: "\
    "directory.person.r, test_app.some.rw - For more information check our docs: "\
    "https://docs.zaikio.com/guide/oauth/scopes.html"] }.to_json, response.body)
  end

  test "forbidden if scope does not have correct permission" do
    token = mock_jwt(scope: ["directory.person.r", "test_app.resources.r"], sub: "Organization/123")
    post "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["unpermitted_scope", "This endpoint requires one of the following scopes: "\
    "test_app.resources.w, test_app.resources.rw but your access token only includes the following scopes: "\
    "directory.person.r, test_app.resources.r - For more information check our docs: "\
    "https://docs.zaikio.com/guide/oauth/scopes.html"] }.to_json, response.body)
  end

  test "is successful if correct JWT was passed" do
    token = mock_jwt(
      sub: "Organization/123",
      scope: ["directory.person.r", "test_app.resources.r"],
      aud: ["directory"]
    )
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal "hello", response.body
    scope = controller.instance_variable_get(:@scope)
    assert_equal TestHelperOrganization, scope.class
    assert_equal "123", scope.id
    audience = controller.instance_variable_get(:@audience)
    assert_equal "directory", audience
    assert_equal(
      {
        "iss" => "ZAI",
        "sub" => "Organization/123",
        "aud" => ["directory"],
        "jku" => "http://hub.zaikio.test/api/v1/jwt_public_keys.json",
        "scope" => ["directory.person.r", "test_app.resources.r"]
      },
      JWT.decode(
        controller.instance_variable_get(:@token), nil, false, algorithms: ["RS256"]
      ).first.except("jti", "nbf", "exp")
    )
  end
end
