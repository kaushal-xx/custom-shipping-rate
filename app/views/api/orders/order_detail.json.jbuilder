json.order do
  json.id @order.id
  json.note @order.note
  json.email @order.email
  json.taxes_included @order.taxes_included
  json.currency @order.currency
  json.subtotal_price @order.subtotal_price
  json.total_tax @order.total_tax
  json.total_price @order.total_price
  json.invoice_sent_at @order.invoice_sent_at
  json.created_at Date.parse(@order.created_at).strftime("%m-%d-%Y")
  json.updated_at Date.parse(@order.updated_at).strftime("%m-%d-%Y")
  json.tax_exempt @order.tax_exempt
  json.international @order.tags.split(",").collect(&:strip).include?("international")? "international" : ""

  if @order.tags.split(",").collect(&:strip).include?("international")
    if @order.tags.include?("RequestedInHandsDate:")
      json.requested_in_hand_date @order.tags.split(",").select{|x| /RequestedInHandsDate:/ =~ x}.first.split(":")[1].strip
    end

    if @order.tags.include?("updated_at:")
      json.ship_updated_at @order.tags.split(",").select{|x| /updated_at:/ =~ x}.first.split(":")[1].strip
    end

    if @order.tags.include?("duties_and_taxes:")
      json.duties_and_taxes @order.tags.split(",").select{|x| /duties_and_taxes:/ =~ x}.first.split(":")[1].strip
    end

    if @order.tags.include?("shipment_terms:")
      json.shipment_terms @order.tags.split(",").select{|x| /shipment_terms:/ =~ x}.first.split(":")[1].strip
    end
  end
  
  if @order.tags.include?("order_id:")
    order = ShopifyAPI::Order.find(@order.tags.split(",").select{|x| /order_id:/ =~ x}.first.split(":")[1].strip) rescue nil
    if order.present?
      json.order_id order.token
    end
  end
  
  if @order.tags.include?("order_name:")
    json.order_name @order.tags.split(",").select{|x| /order_name:/ =~ x}.first.split(":")[1].strip
  end

  json.name @order.name
  json.total_order_quantity @order.line_items.map(&:quantity).reduce(0, :+)
  json.line_items @order.line_items
  json.shipping_address @order.shipping_address
  json.billing_address @order.billing_address
  json.shipping_line  @order.shipping_line
  if (@order.created_at.to_date + 30.days).to_date < Date.today
    json.status "Expired"
  elsif @order.shipping_line.nil?
    json.status "Pending"
  elsif @order.tags.split(",").collect(&:strip).include?("international") || true
    json.status "Completed"
  end
end
json.status "ok"
