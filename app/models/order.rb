class Order < ApplicationRecord
	def self.order_sync(shop)
		shop = Shop.find_by_shopify_domain(shop.shopify_domain) rescue nil
      	sess = ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token)
        ShopifyAPI::Base.activate_session(sess)
        orders_count = @orders = ShopifyAPI::Order.count
        nb_pages      = (orders_count / 250.0).ceil
        # Initializing.
		start_time = Time.now


		1.upto(nb_pages) do |page|
  			unless page == 1
    			stop_time = Time.now
    			puts "Last batch processing started at #{start_time.strftime('%I:%M%p')}"
    			puts "The time is now #{stop_time.strftime('%I:%M%p')}"
    			processing_duration = stop_time - start_time
    			puts "The processing lasted #{processing_duration.to_i} seconds."
    			wait_time = (CYCLE - processing_duration).ceil
    			puts "We have to wait #{wait_time} seconds then we will resume."
    			sleep wait_time if wait_time > 0
    			start_time = Time.now
  			end
  			puts "Doing page #{page}/#{nb_pages}..."
  			orders = ShopifyAPI::Order.find( :all, :params => { :limit => 250, :page => page } )
  			orders.each do |df|
  				puts "==============="
  				puts df.inspect
  				puts df
  				puts "==============="
  				unless df.nil?
  					existing_order = Order.where(:shopify_order_id => df.id)
  					if existing_order.count <= 0
  						if df.try(:customer).nil?
  							customer_id = ShopifyAPI::Customer.where(:email => df.email).first.id
  						else
  							customer_id = df.customer.id
  						end
  						order = Order.new(:email => df.email, :shopify_order_id => df.id, :shopify_customer_id => customer_id, :name => df.name, :company_name => df.try(:shipping_address).try(:company), :shopify_created_at => df.created_at, :shopify_updated_at => df.updated_at)
      					order.save
      				end
      			end
  			end
		end
  	end
end
