class HomeController < ShopifyApp::AuthenticatedController

  def index
  	@state = ShippingWeight.select("state").uniq.order("state")
  	@sheet_headers = ShippingWeight.select("weight").uniq.order("weight ASC")
  	@shipping_weights = ShippingWeight.all
    ss =  ShopifyAPI::CarrierService.find(:all)
    cs = ss.select{|s| s.name == 'Fissler B2B Shipping Rate'}.first
    if cs.blank?
      ss =  ShopifyAPI::CarrierService.new()
      ss.name = "Fissler B2B Shipping Rate"
      ss.callback_url = "https://fissler-b2b-shipping-rate.herokuapp.com/shipping_cal"
      ss.service_discovery = true
      ss.save
    end
  	respond_to do |format|
  		format.html # index.html.erb
  		format.json
  	end 
  end

end
