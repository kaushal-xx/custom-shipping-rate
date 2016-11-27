class ShippingWeight < ApplicationRecord

	def self.get_price(params)
		price = base_price.to_f
		weight = base_weight.to_f
		available_prices = []
		available_shipping = false
		origin_address = params[:rate][:origin]
		destination_address = params[:rate][:destination]
		items = params[:rate][:items]
		total_weight = items.map{|s| s[:grams] * s[:quantity]}.sum
		total_weight_in_ib = '%.2f' % (total_weight*0.0022)
		if weight > 149.00 && weight < 150.00
			weight = 150.00
	    end
		if total_weight_in_ib < 150
			origin_details = {country: origin_address[:country], province: origin_address[:province], city: origin_address[:city], zip: origin_address[:postal_code]}
			destination_details = {country: destination_address[:country], province: destination_address[:province], city: destination_address[:city], zip: destination_address[:postal_code]}
			ups_rates = get_ups_shipping_rate(weight, origin_details, destination_details)
			available_option = ups_rates.select{|k| k.first==shipping_type}.first
			available_prices << ('%.2f' % (available_option.last.to_f/100)) if available_option.present?
	    else
	        shipping_obj = get_shipping_rate(weight, destination_address[:country], destination_address[:province])
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

	def self.get_shipping_rate(weight, country, state)
		weights = ShippingWeight.where("country = ? and state = ?", country, state).order("weight")
		if weights.present?
			if weights.last.weight >= weight
				weights.select{|s| s.weight <= weight}.last
			end
		end
	end

	def self.get_ups_shipping_rate(weight, origin_details, destination_details)
		packages = [ActiveShipping::Package.new(weight*16.1,[12, 8.75, 6], units: :imperial)]
		origin = ActiveShipping::Location.new(origin_details)
		destination = ActiveShipping::Location.new(destination_details)
		ups = ActiveShipping::UPS.new(login: ENV["ups_user_id"], password: ENV["ups_password"], key: ENV["ups_key"])
		response = ups.find_rates(origin, destination, packages)
		response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
	end

	def self.import(file)
		self.delete_all_records
		spreadsheet = Roo::Spreadsheet.open(file)
		headers = Hash.new
		header = spreadsheet.row(1)
		spreadsheet.row(1).each_with_index {|header,i|
			headers[header] = i
		}	
		(2..spreadsheet.last_row).each do |row|
			headers.each do |h|
				if h[1] != 0
					country = spreadsheet.row(row)[0]
					state = spreadsheet.row(row)[1]
					weight = h[0]
					price = spreadsheet.row(row)[h[1]]
					sw = ShippingWeight.new(country: country, state: state, weight: weight, price: price)
					sw.save
				end
			end
		end
	end
	def self.delete_all_records
		ShippingWeight.delete_all 	
	end
end
