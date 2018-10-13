class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :shopify_order_id
      t.string :shopify_customer_id
      t.string :email
      t.string :status
      t.string :name
      t.string :company_name
      t.string :shopify_created_at
      t.string :shopify_updated_at

      t.timestamps null: false
    end
  end
end
