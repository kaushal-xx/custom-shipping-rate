class CreateDraftOrders < ActiveRecord::Migration
  def change
    create_table :draft_orders do |t|
      t.string :shopify_draft_order_id
      t.string :shopify_customer_id
      t.string :email
      t.string :status

      t.timestamps null: false
    end
  end
end
