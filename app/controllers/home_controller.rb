class HomeController < ShopifyApp::AuthenticatedController

  def index
  	@state = ShippingWeight.select("state").uniq.order("state")
  	@sheet_headers = ShippingWeight.select("weight").uniq.order("weight ASC")
  	@shipping_weights = ShippingWeight.all
    ss =  ShopifyAPI::CarrierService.find(:all)
    cs = ss.select{|s| s.name == 'Shipping Custom Rate'}.first
    if cs.blank?
      ss =  ShopifyAPI::CarrierService.new()
      ss.name = "Shipping Custom Rate"
      ss.callback_url = "https://shipping-custom-rate.herokuapp.com/shipping_cal"
      ss.service_discovery = true
      ss.save
    end
  	respond_to do |format|
  		format.html # index.html.erb
  		format.json
  	end 
  end

end
