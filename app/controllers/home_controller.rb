class HomeController < ShopifyApp::AuthenticatedController
  def index
	@state = ShippingWeight.select("state").uniq.order("state")
	@sheet_headers = ShippingWeight.select("weight").uniq.order("weight ASC")
	@shipping_weights = ShippingWeight.all
    ss =  ShopifyAPI::CarrierService.find(:all)
    cs = ss.select{|s| s.name == 'Custom Shipping'}.first
    if cs.blank?
      ss =  ShopifyAPI::CarrierService.new()
      ss.name = "Custom Shipping"
      ss.callback_url = "https://shopify-bulk-order.herokuapp.com/shipping_cal"
      ss.service_discovery = true
      ss.save
    end
	respond_to do |format|
		format.html # index.html.erb
		format.json
	end 
  end

  def shipping_cal
    data = {
        "rates" => [

             {
                 "service_name" => "Shipping + Handling",
                 "service_code" => "ON",
                 "total_price" => ShippingWeight.get_price(params),
                 "description" => "Select this option for all orders",
                 "currency" => "USD"
             }
         ]
      }
    render json: data
  end

end
