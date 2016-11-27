class ShippingWeight < ApplicationRecord

	def self.get_price(params)
		price = base_price.to_f
		weight = base_weight.to_f
		available_prices = []
		available_shipping = false
		if weight <= 150
			shop = ShopifyAPI::Shop.current
			origin_details = {country: shop.country_code, province: shop.province_code, city: shop.city, zip: shop.zip}
			destination_details = {country: country_code, province: province_code, city: city, zip: zip_code}
			ups_rates = get_ups_shipping_rate(weight, origin_details, destination_details)
			available_option = ups_rates.select{|k| k.first==shipping_type}.first
			available_prices << ('%.2f' % (available_option.last.to_f/100)) if available_option.present?
	    else
	        shipping_obj = get_shipping_rate(weight, province_code)
	        if shipping_obj.present?
	        	available_prices << shipping_obj.price.to_f
	        end
	    end
		if available_shipping.blank?
			return 'Error'
		else
		  return (available_prices.blank? ? 'Not found' : available_prices.min)
		end
	end

	def self.get_shipping_rate(weight, state)
		ShippingWeight.where("state = ? and weight >= ?", state, weight).order("weight").first
	end

	def self.get_ups_shipping_rate(weight, origin_details, destination_details)
		packages = [ActiveShipping::Package.new(weight*16.1,[12, 8.75, 6], units: :imperial)]
		origin = ActiveShipping::Location.new(origin_details)
		destination = ActiveShipping::Location.new(destination_details)
		ups = ActiveShipping::UPS.new(login: ENV["ups_user_id"], password: ENV["ups_password"], key: ENV["ups_key"])
		response = ups.find_rates(origin, destination, packages)
		response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
	end
end
