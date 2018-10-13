json.orders @orders do |order|
  json.id order.id
  json.note order.note
  json.email order.email
  json.taxes_included order.taxes_included
  json.currency order.currency
  json.subtotal_price order.subtotal_price
  json.total_tax order.total_tax
  json.total_price order.total_price
  json.invoice_sent_at order.invoice_sent_at
  json.created_at Date.parse(order.created_at).strftime("%m-%d-%Y")
  json.updated_at Date.parse(order.updated_at).strftime("%m-%d-%Y")
  json.tax_exempt order.tax_exempt
  json.international order.tags.split(",").collect(&:strip).include?("international")? "international" :""
  json.name order.name
  json.total_order_quantity order.line_items.map(&:quantity).reduce(0, :+)
  json.line_items order.line_items.each do |lt|
    json.variant_id lt.variant_id
    json.quantity lt.quantity
    json.sku lt.try(:sku)
  end
  json.shipping_address order.shipping_address
  json.billing_address order.billing_address
  json.shipping_line  order.shipping_line
  json.customer_name "#{order.try(:customer).try(:first_name)} #{order.try(:customer).try(:last_name)}"
  if (order.created_at.to_date + 30.days).to_date < Date.today
    json.status "Expired"
  elsif order.shipping_line.nil?
    json.status "Pending"
  elsif order.tags.split(",").collect(&:strip).include?("international") || true
    json.status "Completed"
  end
end
json.total_orders @total_orders
json.per_page @per_page
json.page @page
json.status "ok"
