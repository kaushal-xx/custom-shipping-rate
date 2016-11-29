Rails.application.routes.draw do
  root :to => 'home#index'
  mount ShopifyApp::Engine, at: '/'
  get 'shipping_cal' => "shipping_weights#shipping_cal"
  post 'shipping_cal' => "shipping_weights#shipping_cal"
  get 'rates' => "shipping_weights#rates"
  post 'rates' => "shipping_weights#rates"

  devise_for :users

  resources :shipping_weights do
    post 'upload_location', on: :collection
    post 'update_sheet', on: :collection
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
