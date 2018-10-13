ShopifyApp.configure do |config|
  config.application_name = "My Shopify App"
  config.api_key = "42d9d3cd0d2656e6e986ef450167bc61"
  config.secret = "d2eecd04c478f936df4588d35fcccb66"
  config.scope = "read_orders, read_products, write_orders, write_products, write_draft_orders, read_draft_orders, read_customers, write_customers"
  config.embedded_app = true
end

SITE_URL = 'https://lapinequoteapp.com/'