class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  before_action :set_session

  def set_session
    if params[:shop].present?
  	 shop = Shop.find_by_shopify_domain(params[:shop]) rescue nil
     unless shop.nil?
  	    sess = ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token)
        ShopifyAPI::Base.activate_session(sess)
      end
    end
  end
end
