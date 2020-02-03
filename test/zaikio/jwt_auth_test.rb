require "test_helper"

class Zaikio::JWTAuth::Test < ActiveSupport::TestCase
  def setup
    Zaikio::JWTAuth.configure do |config|
      config.environment = :test
      config.app_name = "test_app"
      config.redis = Redis.new
    end

    stub_requests

    Zaikio::JWTAuth::DirectoryCache.reset("api/v1/blacklisted_token_ids.json")
  end

  test "is a module" do
    assert_kind_of Module, Zaikio::JWTAuth
  end

  test "has version number" do
    assert_not_nil ::Zaikio::JWTAuth::VERSION
  end

  test "it is configurable" do
    Zaikio::JWTAuth.configure do |config|
      config.environment = :test
      config.app_name = "test_app"
      config.redis = Redis.new
    end

    assert_equal :test,                   Zaikio::JWTAuth.configuration.environment
    assert_equal "test_app",              Zaikio::JWTAuth.configuration.app_name
    assert_match "directory.zaikio.test", Zaikio::JWTAuth.configuration.host
    assert_not_nil Zaikio::JWTAuth.configuration.redis
  end

  test "revoked_jwt?" do
    assert Zaikio::JWTAuth.revoked_jwt?("very-bad-token")
    assert_not Zaikio::JWTAuth.revoked_jwt?("other-token")
  end
end

class Organization
  def self.find(id)
    new(id)
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end
end

class Person < Organization
end

class ResourcesController < ApplicationController
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
    klass = token_data.subject_type == "Organization" ? Organization : Person
    @scope = klass.find(token_data.subject_id) # Current.scope
    @audience = token_data.audience
  end
end

class OtherAppResourcesController < ApplicationController
  include Zaikio::JWTAuth

  before_action :authenticate_by_jwt

  authorize_by_jwt_scopes :organization, app_name: "directory"

  def index
    render plain: "hello"
  end
end

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  def setup
    Zaikio::JWTAuth.configure do |config|
      config.environment = :test
      config.app_name = "test_app"
      config.redis = Redis.new
    end

    stub_requests

    Zaikio::JWTAuth::DirectoryCache.reset("api/v1/blacklisted_token_ids.json")

    Rails.application.routes.draw do
      resources :resources
      resources :other_app_resources
    end
  end

  test "unauthorized if no token was passed" do
    get "/resources"
    assert_response :unauthorized
    assert_equal({ "errors" => ["no_jwt_passed"] }.to_json, response.body)
  end

  test "forbidden if invalid JWT was passed" do
    get "/resources", headers: { "Authorization" => "Bearer xxx" }
    assert_response :forbidden
    assert_equal({ "errors" => ["invalid_jwt"] }.to_json, response.body)
  end

  test "forbidden if JWT expired" do
    token = generate_token(exp: 1.hour.ago.to_i)
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["jwt_expired"] }.to_json, response.body)
  end

  test "forbidden if invalid signature" do
    token = generate_token({}, other_dummy_private_key)
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["invalid_jwt"] }.to_json, response.body)
  end

  test "forbidden if invalid subject type" do
    token = generate_token(sub: "Person/abc")
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["unpermitted_subject"] }.to_json, response.body)
  end

  test "forbidden if scope does not exist" do
    token = generate_token(scope: ["directory.person.r", "test_app.some.rw"])
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["unpermitted_scope"] }.to_json, response.body)
  end

  test "forbidden if scope does not have correct permission" do
    token = generate_token
    post "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["unpermitted_scope"] }.to_json, response.body)
  end

  test "forbidden if token was blacklisted" do
    token = generate_token(jti: "very-bad-token")
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["invalid_jwt"] }.to_json, response.body)
  end

  test "is successful if correct JWT was passed" do
    token = generate_token
    get "/resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal "hello", response.body
    scope = controller.instance_variable_get(:@scope)
    assert_equal Organization, scope.class
    assert_equal "123", scope.id
    audience = controller.instance_variable_get(:@audience)
    assert_equal "directory", audience
  end

  test "successful if correct JWT was passed with other app name" do
    token = generate_token
    get "/other_app_resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
  end

  test "forbissen if correct JWT was passed with wrong app name" do
    token = generate_token(
      scope: ["test_app.organization.r"]
    )
    get "/other_app_resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
    assert_equal({ "errors" => ["unpermitted_scope"] }.to_json, response.body)
  end
end
