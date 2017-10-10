class ShippingWeight < ApplicationRecord

	def self.get_price(params, ups_rate = false)
		available_prices = []
		origin_address = params['rate']['origin']
		destination_address = params['rate']['destination']
		items = params['rate']['items']
		total_weight = items.map{|s| s['grams'] * s['quantity']}.sum
		product_weight = ('%.2f' % (total_weight*0.0022)).to_f
		weight_type = ''
		if product_weight > 149.00 && product_weight < 150.00
			weight = 150.00
		else
			weight = product_weight
	    end
	    if weight > 0.0
			if weight < 150
				if weight > light_weight_limit && ups_rate
					ups_price = get_ups_ground_rate(params)
					if ups_price.present?
						available_prices << ups_price
						weight_type = 'UPS Ground'
					end
				else
			        shipping_obj = get_light_weight_shipping_rate(weight, destination_address['country'], destination_address['province'])
			        if shipping_obj.present?
			        	available_prices << shipping_obj.price.to_f
			        	weight_type = 'Light Weight'
			        end		
				end
		    else
		        shipping_obj = get_shipping_rate(weight, destination_address['country'], destination_address['province'])
		        if shipping_obj.present?
		        	available_prices << shipping_obj.price.to_f
		        	weight_type = 'Truck Delivery'
		        end
		    end
		end
		return (available_prices.blank? ? [weight_type, 'Not found'] : [weight_type, available_prices.min])
	end

	def self.get_ups_rates(params)
		origin_address = params['rate']['origin']
		destination_address = params['rate']['destination']
		total_weight = params['rate']['items'].map{|s| s['grams'] * s['quantity']}.sum
		weight = ('%.2f' % (total_weight*0.0022)).to_f
		origin_details = {country: origin_address['country'], province: origin_address['province'], city: origin_address['city'], zip: origin_address['postal_code']}
		destination_details = {country: destination_address['country'], province: destination_address['province'], city: destination_address['city'], zip: destination_address['postal_code']}
		get_ups_shipping_rate(weight, origin_details, destination_details)
	end

	def self.get_ups_second_day_rate(params)
		ups_rates = @usp_response || get_ups_rates(params)
		if ups_rates.present?
			available_option = ups_rates.select{|k| k.first=='UPS Second Day Air'}.first
			 if available_option.present?
			 	'%.2f' % (available_option.last.to_f/100)
			end
		end
	end

	def self.get_ups_ground_rate(params)
		ups_rates = @usp_response || get_ups_rates(params)
		if ups_rates.present?
			available_option = ups_rates.select{|k| k.first=='UPS Ground'}.first
			 if available_option.present?
			 	'%.2f' % (available_option.last.to_f/100)
			end
		end
	end

	def self.ups_shipping_label(params)
		total_weight = params['rate']['items'].map{|s| s['grams'] * s['quantity']}.sum
		weight = ('%.2f' % (total_weight*0.0022)).to_f
		if light_weight_limit > weight
			'Light Weight Expedited'
		elsif light_weight_limit <= weight && weight < 150
			'Standard Ground Expedited'
		elsif weight >= 150
			'Heavy Weight Expedited'
		end
	end

	def self.get_price_for_api(from_address, to_address, total_weight, ups_rate = false)
		available_prices = []
		origin_address = from_address
		destination_address = to_address
		weight_type = ''
		weight = ('%.2f' % (total_weight)).to_f
		if weight > 149.00 && weight < 150.00
			weight = 150.00
	    end
	    if weight > 0.0
			if weight < 150
		        shipping_obj = ShippingWeight.get_light_weight_shipping_rate(weight, destination_address['country'], destination_address['province'])
		        if shipping_obj.present?
		        	available_prices << shipping_obj.price.to_f
		        	weight_type = 'Light Weight'
		        end
		        if ups_rate && available_prices.blank?
					origin_details = {country: origin_address['country'], province: origin_address['province'], city: origin_address['city'], zip: origin_address['postal_code']}
					destination_details = {country: destination_address['country'], province: destination_address['province'], city: destination_address['city'], zip: destination_address['postal_code']}
					ups_rates = ShippingWeight.get_ups_shipping_rate(weight, origin_details, destination_details)
					available_option = ups_rates.select{|k| k.first=='UPS Ground'}.first
					available_prices << ('%.2f' % (available_option.last.to_f/100)) if available_option.present?
					weight_type = 'Standard Ground'
				end
		    else
		        shipping_obj = get_shipping_rate(weight, destination_address['country'], destination_address['province'])
		        if shipping_obj.present?
		        	available_prices << shipping_obj.price.to_f
		        	weight_type = 'Heavy Weight'
		        end
		    end 
		end
		return (available_prices.blank? ? [weight_type, 'Not found'] : [weight_type, available_prices.min])
	end

	def self.valid_params(params)
		errors = []
		if params['from_address'].blank?
			errors << "From Address can't be blank."
		else
			if params['from_address']['country'].blank?
				errors << "Country can't be blank."
			end
			if params['from_address']['province'].blank?
				errors << "Province can't be blank."
			end
			if params['from_address']['city'].blank?
				errors << "City can't be blank."
			end
			if params['from_address']['postal_code'].blank?
				errors << "Postal code can't be blank."
			end
		end
		if params['to_address'].blank?
			errors << "From Address can't be blank."
		else
			if params['to_address']['country'].blank?
				errors << "Country can't be blank."
			end
			if params['to_address']['province'].blank?
				errors << "Province can't be blank."
			end
			if params['to_address']['city'].blank?
				errors << "City can't be blank."
			end
			if params['to_address']['postal_code'].blank?
				errors << "Postal code can't be blank."
			end
		end
		if params['total_weight'].blank?
			errors << "Total weight can't be blank."
		elsif params['total_weight'].to_f <= 0.0
			errors << "Total weight can't less then and equal to zero."
	    end
		errors
	end

	def self.get_shipping_rate(weight, country, state)
		weights = ShippingWeight.where("country = ? and state = ?", country, state).order("weight")
		if weights.present?
			if weights.last.weight >= weight
				weights.select{|s| s.weight <= weight}.last
			end
		end
	end

	def self.get_light_weight_shipping_rate(weight, country, state)
	    if weight <= light_weight_limit
			weights = ShippingWeight.where("country = ? and state = ? and weight <= ?", country, state, weight).order("weight")
			if weights.present?
				weights.last
			else
			    ShippingWeight.where("country = ? and state = ?", country, state).order("weight").first
			end
		end
	end

	def self.light_weight_limit(max_limit = 150)
		weight_obj = ShippingWeight.where("weight < ?", max_limit).order("weight").last
		if weight_obj.present?
			weight_obj.weight
		end
	end

	def self.get_ups_shipping_rate(weight, origin_details, destination_details)
		begin
			packages = [ActiveShipping::Package.new(weight*16.1,[12, 8.75, 6], units: :imperial)]
			origin = ActiveShipping::Location.new(origin_details)
			destination = ActiveShipping::Location.new(destination_details)
			ups = ActiveShipping::UPS.new(login: ENV["ups_user_id"], password: ENV["ups_password"], key: ENV["ups_key"])
			response = ups.find_rates(origin, destination, packages)
			response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
		rescue Exception => e
			puts '***********Error In UPS**********'
			puts e.message
			{}
		end

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
				if h[1] != 0 && h[0].to_f > 0
					country = spreadsheet.row(row)[0]
					state = spreadsheet.row(row)[1]
					weight = h[0].to_f
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
