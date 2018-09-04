ShopifyApp.configure do |config|
  config.api_key = ENV["shopify_api_key"]
  config.secret = ENV["shopify_secret"]
  config.scope = "read_script_tags, write_script_tags, write_shipping, read_orders, read_products, write_orders, write_products, write_draft_orders, read_draft_orders, read_customers, write_customers"
  config.embedded_app = true
end
SITE_URL = 'https://customshippingapp.com/'