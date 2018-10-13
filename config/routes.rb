Rails.application.routes.draw do
  root :to => 'home#index'
  mount ShopifyApp::Engine, at: '/'
  namespace :api do
    post '/draft_order', to: 'orders#draft_order', format: 'json'
    get '/draft_order', to: 'orders#draft_order', format: 'json'
    post '/draft_update', to: 'orders#draft_update', format: 'json'
    get '/list_orders', to: 'orders#list_orders', format: 'json'
    get '/order_detail', to: 'orders#order_detail', format: 'json'
    post '/calculate_shipping_price', to: 'orders#calculate_shipping_price', format: 'json'
    get '/delete_draft_order', to: 'orders#delete_draft_order', format: 'json'
    get '/draft_complete', to: 'orders#draft_complete', format: 'json'
    get '/search_draft_order', to: 'orders#search_draft_order', format: 'json'
    get '/search_order', to: 'orders#search_order', format: 'json'
  end

  resources :shipping_weights do
    post 'upload_location', on: :collection
    post 'update_sheet', on: :collection
  end

  resources :transactions

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
