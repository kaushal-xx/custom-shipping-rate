class Shop < ApplicationRecord
  include ShopifyApp::Shop
  include ShopifyApp::SessionStorage

  def set_store_session
    sess = ShopifyAPI::Session.new(self.shopify_domain, self.shopify_token)
    ShopifyAPI::Base.activate_session(sess)
    # ShopifyAPI::Base.site = "https://b2d36fcd0f1475ba69ef43a4dbbad89b:f6383907850eecde53c06953576ebd77@starwoods-theme.myshopify.com/admin"
    # ShopifyAPI::Session.setup({ api_key: 'b2d36fcd0f1475ba69ef43a4dbbad89b', secret: 'd845fa07a84a8933baf8619634c0bf93' })
  end
end
