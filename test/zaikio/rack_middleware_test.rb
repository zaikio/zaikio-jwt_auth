require "test_helper"

class MiddlewareResourcesController < ApplicationController
  include Zaikio::JWTAuth

  before_action :authenticate_by_jwt, if: -> { params["skip"].blank? }
  authorize_by_jwt_scopes :resources, if: -> { params["skip"].blank? }

  def index
    if request.env["zaikio.jwt.subject"]
      render plain: [request.env["zaikio.jwt.audience"], request.env["zaikio.jwt.subject"]].compact.join(", ")
    else
      render plain: "other_auth"
    end
  end
end

class Zaikio::JWTAuth::RackMiddlewareTest < ActionDispatch::IntegrationTest
  def setup
    Zaikio::JWTAuth.configure do |config|
      config.environment = :test
      config.app_name = "test_app"
      config.cache = ActiveSupport::Cache::RedisCacheStore.new
    end

    stub_requests

    Zaikio::JWTAuth::DirectoryCache.reset("api/v1/revoked_access_tokens.json")

    Rails.application.routes.draw do
      resources :middleware_resources, only: :index
    end
  end

  test "adds env variables through middleware" do
    token = generate_token(exp: 2.hours.from_now.to_i)
    get "/middleware_resources", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal "directory, Organization/123", response.body
  end

  test "works also if other auth header is used" do
    get "/middleware_resources", headers: { "Authorization" => "Bearer #{Base64.encode64('123:other_auth')}" },
                                 params: { skip: "1" }
    assert_response :success
    assert_equal "other_auth", response.body
  end

  test "works also if other auth header is not set" do
    get "/middleware_resources", params: { skip: "1" }
    assert_response :success
    assert_equal "other_auth", response.body
  end
end
