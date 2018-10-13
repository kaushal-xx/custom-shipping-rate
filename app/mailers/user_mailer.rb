class UserMailer < ApplicationMailer
		default from: 'swood@LapineInc.com'

	def draft_order_creation_email(order, shipping_text)
		@order = order
    @shipping_text = shipping_text
		puts "======================"
  		puts @order.inspect
  		puts "======================"
  		if order.shipping_address.country == "United States" || order.shipping_address.country == "Canada"
    		mail(to: @order.customer.email, bcc: "HKalsha@LapineInc.com, NKujur@LapineInc.com, prashant.b.chaudhari@gmail.com", subject: "[Marriott Merchandise] Quote #{@order.name} Created")
    	else
    		@international = true
        attachments["International Freight Quote System The Westin La Quinta 060518.xlsx"] = File.read("#{Rails.root}/public/International_Freight_Quote_temp.xlsx")
    		mail(to: @order.customer.email, cc: "Marriottquoterequest@LapineInc.com", bcc: "HKalsha@LapineInc.com, NKujur@LapineInc.com, prashant.b.chaudhari@gmail.com", subject: "[Marriott Merchandise] Quote #{@order.name} Created")
    	end
  	end

  def draft_order_updation_email(order, shipping_text, flag)
    @flag = flag
    if @flag == true
      @subject = "added"
    else
      @subject = "revised"
    end
    @order = order
    @shipping_text = shipping_text
    puts "======================"
      puts @order.inspect
      puts "======================"
      if order.shipping_address.country == "United States" || order.shipping_address.country == "Canada"
        mail(to: @order.customer.email, bcc: "HKalsha@LapineInc.com, NKujur@LapineInc.com, prashant.b.chaudhari@gmail.com", subject: "[Marriott Merchandise] Quote #{@order.name} #{@subject}")
      else
        @international = true
        mail(to: @order.customer.email, cc: "Marriottquoterequest@LapineInc.com", bcc: "HKalsha@LapineInc.com, NKujur@LapineInc.com, prashant.b.chaudhari@gmail.com", subject: "[Marriott Merchandise] Quote #{@order.name} Shipping price #{@subject} for your quote")
      end
    end

    def draft_order_shipping_alert_email(order, alert_count)
      @alert_count = alert_count
      @order = order
      @international = true
      mail(to: "Marriottquoterequest@LapineInc.com", bcc: "HKalsha@LapineInc.com, NKujur@LapineInc.com, prashant.b.chaudhari@gmail.com", subject: "[Marriott Merchandise] Quote #{@order.name} Shipping #{@subject} : Reminder Alert-#{@alert_count}")
    end
end
