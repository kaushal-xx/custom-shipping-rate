class Api::OrdersController < ApplicationController
	def draft_order
        Shop.first.set_store_session
		customer = ShopifyAPI::Customer.find(params["cid"])
        puts "------------------------------------------------"
        puts customer.inspect
        puts "------------------------------------------------"
        line_items = []
        if params["cart"]["items"].nil?
            respond_to do |format|
                format.json { render json: {'message' => 'Quotation Cart is empty.' } }
            end
        else
            params["cart"]["items"].each do |lt|
                line_items << {:variant_id => lt["variant_id"], :quantity => lt["quantity"], :grams => lt["weight"]}
            end
        end
        if ["United States", "Canada"].include?(params["shipping_address"]["country"])
            @order = ShopifyAPI::DraftOrder.new(:email => customer.email, :line_items => line_items, :shipping_address => params["shipping_address"], :billing_address => params["billing_address"], :shipping_line => { "handle": nil, "price": params["shipping_price"], "title": "Standard Shipping", "custom": true}, :note => params[:note], :tags => "app_quote")
            order_type = "domestic"
        else
            @shipping_text = params["shipping_text"]
            if params["RequestedInHandsDate"].present?
                @order = ShopifyAPI::DraftOrder.new(:email => customer.email, :line_items => line_items, :shipping_address => params["shipping_address"], :billing_address => params["billing_address"], :note => params[:note], :tags => "app_quote, international, RequestedInHandsDate:#{params[:RequestedInHandsDate]}")
            else
                @order = ShopifyAPI::DraftOrder.new(:email => customer.email, :line_items => line_items, :shipping_address => params["shipping_address"], :billing_address => params["billing_address"], :note => params[:note], :tags => "app_quote, international")
            end
            order_type = "international"
        end    
        puts "------------------Ordereee------------------------------"
        puts @order.errors.full_messages
        puts "---------------------Ordeerr---------------------------"
	    if @order.save
          @draft_order = DraftOrder.new(:email => @order.email, :shopify_draft_order_id => @order.id, :shopify_customer_id => @order.customer.id, :status => @order.status, :order_type => order_type, :name => @order.name, :company_name => @order.try(:shipping_address).try(:company), :shopify_created_at => @order.created_at, :shopify_updated_at => @order.updated_at)
          @draft_order.save
          if order_type == "international"
              DraftOrder.create_freight(@order)
          end
          UserMailer.draft_order_creation_email(@order, @shipping_text).deliver
		  respond_to do |format|
            format.json { render json: {'message' => 'Quotation Created Successfully', :id => @order.id ,:status => "200" } }
            end
	    else
		 render json: {error: "Post is invalid", status: 400}, status: 400
        end
    end

    def draft_update

        if params[:id].present? && params[:shipping_price].present? && params[:duties_and_taxes].present? && params[:shipment_terms].present?
            @draft = ShopifyAPI::DraftOrder.find(params[:id]) rescue nil

            if @draft.present?
                if @draft.shipping_line.nil?
                    @flag = true
                    @draft.shipping_line = Array.new
                else
                    @flag = false
                end


                shipping_line = ShopifyAPI::ShippingLine.new({"handle"=>nil, "price"=>params[:shipping_price].to_f + params[:duties_and_taxes].to_f, "title"=>"International Shipping", "custom"=>true})

                @draft.shipping_line = shipping_line
                puts "============date update================="
                puts ShopifyAPI::Shop.current.timezone
                puts "============date update================="
                tags = @draft.tags.split(", ").delete_if {|i| i.include?("updated_at:")}
                @draft.tags = tags.push("updated_at:#{ Time.now.strftime('%m-%d-%Y')}").join(", ")
                @draft.tags = @draft.tags + ", duties_and_taxes:#{params[:duties_and_taxes]}"

                if params[:shipment_terms].present? 
                    tags = @draft.tags.split(", ").delete_if {|i| i.include?("shipment_terms:")}
                    @draft.tags = tags.push("shipment_terms:#{params[:shipment_terms]}").join(", ")
                end
                
                if @draft.save
                   UserMailer.draft_order_updation_email(@draft, nil, @flag).deliver 
                   render json: { message: 'Quotation Saved Successfully' ,status: 200 }
                else
                   render json: { error: @draft.error.full_messages ,status: 400 }
                end
            else
                render json: { error: @draft.error.full_messages ,status: 400 }
            end
        else
            render json: { error: 'Insufficient params provided' ,status: 400 }
        end
    end

    def list_orders
        # @orders = ShopifyAPI::DraftOrder.find(:all, params: {limit: 150, status: 'open'}).select{ |arr| (arr.try(:customer).try(:id).to_s.eql? params["cid"].to_s) && (arr.tags.include?("app_quote") )}.sort_by { |obj| obj.created_at }.reverse!

        if params[:start_date].present? && params[:end_date].present?
            start_date = params[:start_date]
            end_date = params[:end_date]
        else
            start_date = DraftOrder.first.shopify_created_at.to_date
            end_date = Date.today
        end

        if params[:concierge].present?
            cid = "%#{rand(10)}%"
        else
            cid = "%#{params[:cid]}%"
        end

        if params[:search_term].present? 
            local_db_name = DraftOrder.where("shopify_customer_id LIKE ?", cid).where("lower(name) LIKE ?", "%#{params[:search_term].downcase}%").where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}") 
            @orders = ShopifyAPI::DraftOrder.where(ids: local_db_name.map(&:shopify_draft_order_id).join(",")) rescue []
            if @orders.count <= 0
                local_db_name = DraftOrder.where("shopify_customer_id LIKE ?", cid).where("lower(company_name) = ?", params[:search_term].downcase).where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}")
                local_db_name = local_db_name.paginate(:page => params[:page], :per_page => params[:per_page]) 
                @total_orders =  local_db_name.count
                @orders = ShopifyAPI::DraftOrder.where(ids: local_db_name.map(&:shopify_draft_order_id).join(",")) rescue []
            end
            if @orders.count <= 0 && params[:concierge].present?
                search_term = params[:search_term].strip.split(" ")
                query = "first_name:'#{search_term.first}'"
                if search_term.size > 1
                    query = query + " last_name:'#{search_term.last}'"
                end
                
                @customer = ShopifyAPI::Customer.search(query: query)
                
                # @orders = ShopifyAPI::DraftOrder.where(:email => @customer.map(&:email))
                @local_orders = DraftOrder.where(:shopify_customer_id => @customer.map(&:id).uniq).where(:status => "open").where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}").order('created_at DESC')
                @total_orders =  @local_orders.count
                order_ids_locals = @local_orders.paginate(:page => params[:page], :per_page => params[:per_page]).map(&:shopify_draft_order_id) rescue nil

                @orders = ShopifyAPI::DraftOrder.where(ids: "#{order_ids_locals.join(",")}").sort_by(&:created_at).reverse rescue []
            end
        # elsif params[:concierge].present?
            # @local_orders = DraftOrder.where(:status => "open").where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}").order('created_at DESC')
            # :order_type => "international",
            # @total_orders = @local_orders.count 
            # order_ids_locals = @local_orders.paginate(:page => params[:page], :per_page => params[:per_page]).map(&:shopify_draft_order_id) rescue nil
            # @orders = ShopifyAPI::DraftOrder.where(ids: "#{order_ids_locals.join(",")}").sort_by(&:created_at).reverse rescue []
        else
            @local_orders = DraftOrder.where("shopify_customer_id LIKE ?", cid).where(:status => "open").where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}").order('created_at DESC')
            @total_orders = @local_orders.count 
            order_ids_locals = @local_orders.paginate(:page => params[:page], :per_page => params[:per_page]).map(&:shopify_draft_order_id) rescue nil
            @orders = ShopifyAPI::DraftOrder.where(ids: "#{order_ids_locals.join(",")}").sort_by(&:created_at).reverse rescue []
        end   

        # if params[:start_date].present? && params[:end_date].present?  
        #     if @orders.count <= 0
        #         local_db_name = DraftOrder.where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{params[:start_date]}","#{params[:end_date]}") 
        #         local_db_name = local_db_name.paginate(:page => params[:page], :per_page => params[:per_page]) 
        #         @total_orders =  local_db_name.count
        #         @orders = ShopifyAPI::DraftOrder.where(ids: "#{local_db_name.map(&:shopify_draft_order_id).join(",")}") rescue []    
        #     else
        #         local_db_name = @orders.map(&:name)
        #         local_db_name = DraftOrder.where(:name => local_db_name).where(:status => "open").where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{params[:start_date]}","#{params[:end_date]}").order('created_at DESC')
        #         local_db_name = local_db_name.paginate(:page => params[:page], :per_page => params[:per_page]) 
        #         @total_orders =  local_db_name.count
        #         @orders = ShopifyAPI::DraftOrder.where(ids: "#{local_db_name.map(&:shopify_draft_order_id).join(",")}") rescue []
        #     end
        # end
        

        @per_page = params[:per_page]
        @page = params[:page]
        
        if @orders.count <= 0
            render json: {error: "No Quote found", status: 200}
        end
    end

    def order_detail
       @order = ShopifyAPI::DraftOrder.find(params[:id]) rescue nil
       puts "-----------------------"
       puts @order.inspect
       puts "-----------------------"
        if @order.nil?
            render json: {error: "No Quote found", status: 200}
        end
    end

    def calculate_shipping_price
        puts "---------params---------------"
        puts params
        puts "----------shipping_address--------------"
        puts params["shipping_address"]
        puts "------------line_items------------"
        puts params["line_items"]
        puts "------------------------"
        shipping_attr = {}
        shipping_attr['origin'] = {address1: "15 Commerce Rd", city: "Lebanon", state: "KS", zip: "66952", country: "US"}
        shipping_attr['destination'] = params["shipping_address"]
        shipping_attr['items'] = params["line_items"]
        shipping_label, shipping_price = ShippingWeight.get_price(shipping_attr)
        puts "11111111111111111111111111"
        puts shipping_price.inspect
        puts "11111111111111111111111111"
        shipping_lines = []
        if shipping_price
            shipping_lines = [{code: 'draft_order',
                              price: shipping_price.to_f+8.00,
                              source: 'Shipping Darft Order',
                              title: ' Darft Order',
                              carrier_identifier: 'shipping_darft_order_app'}]
        end
        if shipping_lines.count <= 0
            render json: {error: "No Shipping lines found", status: 400}
        else
            render json: {error: "Shipping lines found", :shipping_lines => shipping_lines, status: 200}
        end
    end

    def delete_draft_order
       @order = ShopifyAPI::DraftOrder.find(params[:id]) rescue nil
       if @order.nil?
        render json: {error: "No Quote found", status: 200}
       else
        if @order.destroy
            render json: {success: "Draft Order deleted Successfully.", status: 200}
        end
       end
    end

    # def draft_complete
    #     @order = ShopifyAPI::Order.find(params[:id]) rescue nil
    #     draft_id  = nil
    #     @order.note_attributes.each do |atr|
    #         if atr.attributes["name"] == "quote_id"
    #             draft_id = atr.attributes["value"]
    #             puts "-----------------------"
    #             puts draft_id
    #             puts "-----------------------"
    #         end
    #     end
    #     if  draft_id.nil?
    #         render json: {error: "Order id not found.", status: 400}
    #     else
    #         @draft_order = ShopifyAPI::DraftOrder.find(draft_id)
    #         if @draft_order.status == "completed"
    #             render json: {error: "Order is not open.", status: 400}
    #         else
    #             @draft_order.tags = @draft_order.tags + ", order:#{@order.name}"
    #             @draft_order.complete("order": {"payment_pending": true })
    #             puts "====================="
    #             puts @draft_order
    #             puts "====================="
    #             if @draft_order.save
    #                 puts "====================="
    #                 puts @draft_order.order_id
    #                 puts "====================="
    #                 if @draft_order.order_id.present?
    #                     order_to_delete = ShopifyAPI::Order.find(@draft_order.order_id)
    #                     order_to_delete.cancel({"order":{"amount": order_to_delete.total_price, "reason": "Other", "restock": true}})
    #                     if order_to_delete.save
    #                         if order_to_delete.destroy
    #                             render json: {success: "Order deleted Successfully.", status: 200}         
    #                         else
    #                             render json: {error: "Order deleted Successfully.", status: 200}     
    #                         end    
    #                     else
    #                         render json: {error: "Order not saved Successfully.", status: 200}     
    #                     end
    #                 else
    #                     render json: {error: "Order not deleted Successfully.", status: 400}         
    #                 end    
    #             else
    #                 render json: {error: "Draft order not present.", status: 400}         
                
    #             end
    #         end
    #     end
    # end

   def search_order
        if params[:start_date].present? && params[:end_date].present?
            start_date = params[:start_date]
            end_date = params[:end_date]
        else
            start_date = Order.first.shopify_created_at.to_date
            end_date = Date.today
        end

        if params[:search_term].present? 
            local_db_name = Order.where("lower(name) = ?", params[:search_term].downcase).where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}") 
            @orders = ShopifyAPI::Order.where(ids: "#{local_db_name.first.shopify_draft_order_id}") rescue []
            if @orders.count <= 0
                local_db_name = Order.where("lower(company_name) = ?", params[:search_term].downcase).where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}")
                local_db_name = local_db_name.paginate(:page => params[:page], :per_page => params[:per_page]) 
                @total_orders =  local_db_name.count
                @orders = ShopifyAPI::Order.where(ids: "#{local_db_name.first.shopify_draft_order_id}") rescue []
            end
            if @orders.count <= 0

                search_term = params[:search_term].strip.split(" ")
                query = "first_name:'#{search_term.first}'"
                if search_term.size > 1
                    query = query + " last_name:'#{search_term.last}'"
                end

                puts "============query============="
                puts query
                puts "============query============="
                
                @customer = ShopifyAPI::Customer.search(query: query)
                
                # @orders = ShopifyAPI::DraftOrder.where(:email => @customer.map(&:email))
                @local_orders = Order.where(:shopify_customer_id => @customer.map(&:id).uniq).where("DATE(shopify_created_at) BETWEEN ? AND ?", "#{start_date}","#{end_date}").order('created_at DESC')
                @total_orders =  @local_orders.count
                order_ids_locals = @local_orders.paginate(:page => params[:page], :per_page => params[:per_page]).map(&:shopify_draft_order_id) rescue nil

                puts "===*=====*=====order_ids_locals=====*====*==="
                puts order_ids_locals
                puts "===*=====*=====order_ids_locals=====*====*==="

                @orders = ShopifyAPI::Order.where(ids: "#{order_ids_locals.join(",")}").sort_by(&:created_at).reverse rescue []
            end
        end
        @per_page = params[:per_page]
        @page = params[:page]
        
        if @orders.count <= 0
            render json: {error: "No Quote found", status: 200}
        end
    end

    def draft_complete
        @order = ShopifyAPI::Order.find(params[:id]) rescue nil
        draft_id  = nil
        @order.note_attributes.each do |atr|
            if atr.attributes["name"] == "quote_id"
                draft_id = atr.attributes["value"]
                puts "-----------------------"
                puts draft_id
                puts "-----------------------"
            end
        end

        if  draft_id.nil?
            render json: {error: "Order id not found.", status: 400}
        else
            @draft_order = ShopifyAPI::DraftOrder.find(draft_id)
            @draft_order.tags = @draft_order.tags + ", order_id:#{@order.id}, order_name:#{@order.name}"
            puts "====================="
            puts @draft_order
            puts "====================="
            if @draft_order.save
                @local_draft_order = DraftOrder.find_by_shopify_draft_order_id(draft_id)
                @local_draft_order.status = "completed"
                if @local_draft_order.save
                    render json: {error: "Draft updated Successfully.", status: 200}         
                else
                    render json: {error: "Draft not updated Successfully.", status: 400}         
                end
            else
                render json: {error: "Draft order not present.", status: 400}         
                
            end
        end
    end

end
