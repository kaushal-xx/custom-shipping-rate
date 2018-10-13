class DraftOrder < ApplicationRecord
  after_create :trigger_delayed_job
  require 'rubyXL'

  def trigger_delayed_job
    shop = Shop.first
    sess = ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token)
    ShopifyAPI::Base.activate_session(sess)

    darft_order = ShopifyAPI::DraftOrder.find(self.shopify_draft_order_id)
    if darft_order.tags.include?("international")
      DraftOrder.delay(run_at: 2.minutes.from_now).set_shipping_alert(self, 1)
      DraftOrder.delay(run_at: 4.minutes.from_now).set_shipping_alert(self, 2)
      DraftOrder.delay(run_at: 7.minutes.from_now).set_shipping_alert(self, 3)
      DraftOrder.delay(run_at: 9.minutes.from_now).set_shipping_alert(self, 4)
    end  
  end

  def self.set_shipping_alert(df, alert_count)
    shop = Shop.first
    sess = ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token)
    ShopifyAPI::Base.activate_session(sess)
    darft_order = ShopifyAPI::DraftOrder.find(df.shopify_draft_order_id)
    if darft_order.shipping_line.nil?
      UserMailer.draft_order_shipping_alert_email(darft_order, alert_count).deliver
    end
  end

  def self.draft_order_sync(shop)
		shop = Shop.find_by_shopify_domain(shop.shopify_domain) rescue nil
      	sess = ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token)
        ShopifyAPI::Base.activate_session(sess)
        draft_orders_count = @draft_orders = ShopifyAPI::DraftOrder.count
        nb_pages      = (draft_orders_count / 250.0).ceil
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
  			draft_orders = ShopifyAPI::DraftOrder.find( :all, :params => { :limit => 250, :page => page } )
  			draft_orders.each do |df|
  				puts "==============="
  				puts df.inspect
  				puts df
  				puts "==============="
  				unless df.nil?
  					existing_draft_order = DraftOrder.where(:shopify_draft_order_id => df.id)
  					if existing_draft_order.count <= 0
  						if df.tags.include?("international") 
  							order_type = "international"
  						else
  							order_type = "domestic"
  						end
  						draft = DraftOrder.new(:email => df.email, :shopify_draft_order_id => df.id, :shopify_customer_id => df.customer.try(:id), :status => df.status, :order_type => order_type, :name => df.name, :company_name => df.try(:shipping_address).try(:company), :shopify_created_at => df.created_at, :shopify_updated_at => df.updated_at)
      				draft.save if df.tags.include?("app_quote")
      			end
      		end
  			end
		end
  end

  def self.create_freight(draft_order)
    workbook = RubyXL::Parser.parse("#{Rails.root}/public/International_Freight_Quote.xlsx")
    fob = draft_order.shipping_address.zip
    country = draft_order.shipping_address.country
    draft_order.line_items.each_with_index do |lt, index|
      puts "---------------------------------Lie Item--------------"
puts  lt.title
puts "---------------------------------Lie Item--------------"


      if lt.title.downcase.include?('(') && lt.title.downcase.include?('case of') && lt.title.downcase.include?('(')
        case_data = lt.title.downcase.split('(').last.split(')').first.strip
        uom = "Case"
        case_pack = case_data.split("case of ").last
        qty_ordered = "#{lt.quantity} cases of #{case_pack}"
      else
        uom = "Each"
        case_pack = "1"
        qty_ordered = "1 eaches"
      end
      row = workbook["International Quote Form"].insert_row(60 + index)
      row = workbook["International Quote Form"].sheet_data[60 + index]
      # row.cells[0].change_contents(nil)
      row.cells[1].change_contents(lt.sku)
      row.cells[2].change_contents(lt.title)
      row.cells[3].change_contents(nil)
      row.cells[4].change_contents("Lapine Inc.")
      row.cells[5].change_contents(uom)
      row.cells[6].change_contents(case_pack)
      row.cells[7].change_contents(qty_ordered)
      row.cells[8].change_contents(lt.price * lt.quantity)
      row.cells[9].change_contents(lt.vendor)
      row.cells[10].change_contents(nil)
      row.cells[11].change_contents(lt.grams * lt.quantity)
      row.cells[12].change_contents(nil)
      row.cells[13].change_contents(fob)
      row.cells[14].change_contents(country)
    end

    workbook["International Quote Form"].delete_row(59)

    workbook.write("#{Rails.root}/public/International_Freight_Quote_temp.xlsx")
  end
end
