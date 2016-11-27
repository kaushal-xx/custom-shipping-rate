ShopifyApp.configure do |config|
  config.api_key = ENV["shopify_api_key"]
  config.secret = ENV["shopify_secret"]
  config.scope = "read_script_tags, write_script_tags, write_shipping"
  config.embedded_app = true
end
SITE_URL = 'https://shopify-bulk-order.herokuapp.com'