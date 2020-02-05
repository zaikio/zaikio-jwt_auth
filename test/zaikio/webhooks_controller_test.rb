require "test_helper"

class WebhooksController < ApplicationController
  include Zaikio::JWTAuth

  before_action :verify_signature
  before_action :update_blacklisted_access_tokens_by_webhook

  def create
    render json: { received: true }
  end

  private

  def verify_signature
    # Read More: https://docs.zaikio.com/guide/loom/receiving-events.html
    unless ActiveSupport::SecurityUtils.secure_compare(
      OpenSSL::HMAC.hexdigest("SHA256", "shared-secret", request.body.read),
      request.headers["X-Loom-Signature"]
    )
      render json: { received: true }
    end
  end
end

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    Zaikio::JWTAuth.configure do |config|
      config.environment = :test
      config.app_name = "test_app"
      config.redis = Redis.new
    end

    stub_requests

    Rails.application.routes.draw do
      resources :webhooks
    end

    Zaikio::JWTAuth::DirectoryCache.reset("api/v1/blacklisted_access_tokens.json")

    @event = {
      name: "directory.revoked_access_token",
      payload: {
        access_token_id: "my-webhook-token"
      }
    }
  end

  def signature(event, key = "shared-secret")
    OpenSSL::HMAC.hexdigest("SHA256", key, event.to_json)
  end

  test "success if signature is invalid but does not add token" do
    post "/webhooks", params: @event.to_json,
                      headers: { "Content-Type" => "application/json",
                                 "X-Loom-Signature" => signature(@event, "wrong-key") }
    assert_response :success
    cache = Zaikio::JWTAuth::DirectoryCache.fetch("api/v1/blacklisted_access_tokens.json")
    assert_not_equal "my-webhook-token", cache["blacklisted_token_ids"].last
  end

  test "adds token to blacklisted tokens" do
    post "/webhooks", params: @event.to_json,
                      headers: { "Content-Type" => "application/json", "X-Loom-Signature" => signature(@event) }
    assert_response :success
    cache = Zaikio::JWTAuth::DirectoryCache.fetch("api/v1/blacklisted_access_tokens.json")
    assert_equal "my-webhook-token", cache["blacklisted_token_ids"].last
    assert_equal({ "received" => true }.to_json, response.body)
  end

  test "does nothing on other event" do
    @event[:name] = "directory.other_event"
    post "/webhooks", params: @event.to_json,
                      headers: { "Content-Type" => "application/json", "X-Loom-Signature" => signature(@event) }
    assert_response :success
    assert_equal({ "received" => true }.to_json, response.body)
  end
end
