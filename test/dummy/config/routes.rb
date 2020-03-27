Rails.application.routes.draw do
  mount Zaikio::Webhooks::Engine => "/zaikio/webhook"
end
