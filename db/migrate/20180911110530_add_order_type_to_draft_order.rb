class AddOrderTypeToDraftOrder < ActiveRecord::Migration
  def change
    add_column :draft_orders, :order_type, :string
  end
end
