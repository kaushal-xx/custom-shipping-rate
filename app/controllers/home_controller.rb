class HomeController < ShopifyApp::AuthenticatedController

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

end
