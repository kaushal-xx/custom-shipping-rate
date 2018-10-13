class AddShopifyCraetedAtToDraftOrder < ActiveRecord::Migration
  def change
    add_column :draft_orders, :shopify_created_at, :string
    add_column :draft_orders, :shopify_updated_at, :string
  end
end
