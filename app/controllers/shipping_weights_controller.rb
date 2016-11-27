class ShippingWeightsController < ApplicationController
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

  def upload_location
    ShippingWeight.import(params[:csv_upload])
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
