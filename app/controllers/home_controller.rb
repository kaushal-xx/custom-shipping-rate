class HomeController < ApplicationController

  before_action :authenticate_user!

  def index
    @state = ShippingWeight.select("state").uniq.order("state")
    @sheet_headers = ShippingWeight.select("weight").uniq.order("weight ASC")
    @shipping_weights = ShippingWeight.all
    respond_to do |format|
      format.html # index.html.erb
      format.json
    end  
  end

end
