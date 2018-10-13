class ApiController < ApplicationController
	# Api for draft Order creation.
	def daft_order
		 new_order = ShopifyAPI::Order.new(
      		:note => params[:note],
      		:gateway => @order.try(:gateway),
      		:test => @order.try(:test),
      		:total_price => params[:total_price],
      		:total_weight => params[:total_weight],
      		:currency => params[:currency],
      		:note_attributes => params[:note],
      		:tags => "",
      		:line_items => params[:line_items]
    	)

		 if new_order.save
      respond_to do |format|
                format.json { render json: {'message' => 'Order Saved Successfully', :status => "200" } }
            end
		end
	end
end
