class AddNameToDraftOrder < ActiveRecord::Migration
  def change
    add_column :draft_orders, :name, :string
  end
end
