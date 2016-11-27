class HomeController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:shipping_cal]

  def index
  	@state = ShippingWeight.select("state").uniq.order("state")
  	@sheet_headers = ShippingWeight.select("weight").uniq.order("weight ASC")
  	@shipping_weights = ShippingWeight.all
    ss =  ShopifyAPI::CarrierService.find(:all)
    cs = ss.select{|s| s.name == 'Custom Shipping'}.first
    if cs.blank?
      ss =  ShopifyAPI::CarrierService.new()
      ss.name = "Custom Shipping"
      ss.callback_url = "https://custom-shipping-rate.herokuapp.com/shipping_cal"
      ss.service_discovery = true
      ss.save
    end
  	respond_to do |format|
  		format.html # index.html.erb
  		format.json
  	end 
  end

  def shipping_cal
    shipping_price = ShippingWeight.get_price(params)
    Rails.logger.info "*************************"
    puts shipping_price
    Rails.logger.info "*************************"
    if shipping_price.to_f > 0.0
      data = {
          "rates" => [

               {
                   "service_name" => "Shipping + Handling",
                   "service_code" => "ON",
                   "total_price" => shipping_price.to_f,
                   "description" => "Select this option for all orders",
                   "currency" => "USD"
               }
           ]
        }
    else
      data = {}
    end
    render json: data
  end

end
