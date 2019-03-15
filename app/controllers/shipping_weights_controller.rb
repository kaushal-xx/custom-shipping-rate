class ShippingWeightsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :shipping_cal, :rates]
  skip_before_filter :verify_authenticity_token, :only => [:upload_location, :shipping_cal,:rates]
  before_action :set_shipping_weight, only: [:show, :edit, :update, :destroy]
  before_action :set_shipping_weight_state_weight, only: [:update_sheet]

  # GET /shipping_weights
  # GET /shipping_weights.json
  def index
    @state = ShippingWeight.select("state").uniq.order("state")
    @sheet_headers = ShippingWeight.select("weight").uniq.order("weight ASC")
    @shipping_weights = ShippingWeight.all
    respond_to do |format|
      format.html # index.html.erb
      format.json
    end  
  end

  def shipping_cal
    # Parameters: {"rate"=>{"origin"=>{"country"=>"US", "postal_code"=>"01821", "province"=>"MA", "city"=>"BILLERICA", "name"=>nil, "address1"=>"17 Progress Rd.", "address2"=>"", "address3"=>nil, "phone"=>"9786420348", "fax"=>nil, "email"=>nil, "address_type"=>nil, "company_name"=>"Marriott Merchandise by Lapine"}, "destination"=>{"country"=>"US", "postal_code"=>"06902", "province"=>"CT", "city"=>"Stamford", "name"=>"Test Customer", "address1"=>"15 Commerce Rd", "address2"=>"", "address3"=>nil, "phone"=>"(203) 353-3080", "fax"=>nil, "email"=>nil, "address_type"=>nil, "company_name"=>"Test"}, "items"=>[{"name"=>"Westin Pet Welcome Kit (Case of 100)", "sku"=>"SW-DB68WE", "quantity"=>1, "grams"=>7711, "price"=>11410, "vendor"=>"Starwood Merchandise", "requires_shipping"=>true, "taxable"=>true, "fulfillment_service"=>"manual", "properties"=>nil, "product_id"=>219157626906, "variant_id"=>3237115920410}, {"name"=>"Sheraton Pet Welcome Kit (Case of 100)", "sku"=>"SW-DB68SH", "quantity"=>1, "grams"=>7711, "price"=>11410, "vendor"=>"Starwood Merchandise", "requires_shipping"=>true, "taxable"=>true, "fulfillment_service"=>"manual", "properties"=>nil, "product_id"=>219157659674, "variant_id"=>3237115953178}], "currency"=>"USD", "locale"=>"en"}, "shipping_weight"=>{}}
    params.with_indifferent_access
    puts "=================================="
    puts params[:rate][:items].map{|x| x[:vendor]}.uniq.first
    puts "=================================="
    if params[:rate][:items].map{|x| x[:vendor]}.uniq.first == 'Weber Apparel' && params[:rate][:items].map{|x| x[:vendor]}.uniq.count == 1 && params[:rate][:items].map{|x| x[:quantity]}.sum < 50
      price = WeberShippingRate.where("min_qty <= #{params[:rate][:items].map{|x| x[:quantity]}.sum} AND max_qty >= #{params[:rate][:items].map{|x| x[:quantity]}.sum}").first.rate.to_f
      shipping_price = ["UPS Ground", price]
    elsif params[:rate][:items].map{|x| x[:vendor]}.join(",").downcase.include?("weber") &&  !params[:rate][:items].map{|x| x[:vendor]}.join(",").downcase.include?('apparel')
      shipping_price = ["UPS Ground", "Custom Shipping Price", 0.0]
    else
      shipping_price = ShippingWeight.get_price(params, true)
    end

    
    Rails.logger.info "*************************"
    puts shipping_price
    Rails.logger.info "*************************"
    if shipping_price.last.to_f > 0.0 || (shipping_price.second == 'Custom Shipping Price' && shipping_price.last.to_f >= 0.0)
      if shipping_price.size <= 2 
        shipping_rate = shipping_price.last.to_f + 8.00
      else
        shipping_rate = shipping_price.last.to_f
      end
      data = {
          "rates" => [

               {
                   "service_name" => "#{shipping_price.first}",
                   "service_code" => "ON",
                   "total_price" => shipping_rate*100,
                   "description" => "Select this option for all orders",
                   "currency" => "USD"
               }
           ]
        }
      if shipping_price.size <= 2 && !params[:rate][:items].map{|x| x[:vendor]}.join(",").downcase.include?("weber")
        ups_second_day, label = ShippingWeight.get_ups_second_day_rate(params)
        ups_second_day, label = ShippingWeight.get_ups_expedited_rate(params) if ups_second_day.blank?
        if ups_second_day.present?
          data['rates'] << {
            "service_name" => label,
            "service_code" => "ON",
            "total_price" => (ups_second_day.to_f+ 8.00)*100,
            "description" => "Select this option for all orders",
            "currency" => "USD"
          }
        end
      end
    else
      data = {}
    end
    render json: data
  end

  def rates
    errors = ShippingWeight.valid_params(params)
    data = {}
    if errors.blank?
      begin
        shipping_price = ShippingWeight.get_price_for_api(params['from_address'], params['to_address'], params['total_weight'], true)
        Rails.logger.info "*************************"
        puts shipping_price
        Rails.logger.info "*************************"
        if shipping_price.last.to_f > 0.0
          shipping_rate = shipping_price.last.to_f + 8.00
          data = { rates: { total_price: shipping_rate.to_f, currency: "USD", shipping_type: "#{shipping_price.first}"} }
        else
          data = {errors: ["Shipping rate can't calculate."]}
        end
      rescue Exception => e
        data = { errors: e }
      end
    else
      data = { errors: errors }
    end
    render json: data
  end

  def upload_location
    ShippingWeight.import(params[:file])
    respond_to do |format|
      format.html { redirect_to shipping_weights_url}
      format.json { head :no_content }
    end
  end

  def update_sheet       
      #abort params[:shipping_weight][:state].inspect
    respond_to do |format|
      if @shipping_weight.update(state: params[:shipping_weight][:state], weight: params[:shipping_weight][:weight], price: params[:shipping_weight][:price])
        format.json { render nothing: true, status: :ok }
      else
        format.json { render json: @shipping_weight.errors, status: :unprocessable_entity }
      end
    end

  end

  # GET /shipping_weights/1
  # GET /shipping_weights/1.json
  def show
  end

  # GET /shipping_weights/new
  def new
    @shipping_weight = ShippingWeight.new
  end

  # GET /shipping_weights/1/edit
  def edit
  end

  # POST /shipping_weights
  # POST /shipping_weights.json
  def create
    @shipping_weight = ShippingWeight.new(shipping_weight_params)

    respond_to do |format|
      if @shipping_weight.save
        format.html { redirect_to @shipping_weight, notice: 'Shipping weight was successfully created.' }
        format.json { render :show, status: :created, location: @shipping_weight }
      else
        format.html { render :new }
        format.json { render json: @shipping_weight.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shipping_weights/1
  # PATCH/PUT /shipping_weights/1.json
  def update
    respond_to do |format|
      if @shipping_weight.update(shipping_weight_params)
        format.html { redirect_to @shipping_weight, notice: 'Shipping weight was successfully updated.' }
        format.json { render :show, status: :ok, location: @shipping_weight }
      else
        format.html { render :edit }
        format.json { render json: @shipping_weight.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shipping_weights/1
  # DELETE /shipping_weights/1.json
  def destroy
    @shipping_weight.destroy
    respond_to do |format|
      format.html { redirect_to shipping_weights_url, notice: 'Shipping weight was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shipping_weight
      @shipping_weight = ShippingWeight.find(params[:id])
    end

    def set_shipping_weight_state_weight
      @shipping_weight = ShippingWeight.where(state: params[:shipping_weight][:state], weight: params[:shipping_weight][:weight]).first
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def shipping_weight_params
      params.require(:shipping_weight).permit(:state, :weight, :price)
    end
end
