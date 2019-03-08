class CreateWeberShippingRates < ActiveRecord::Migration[5.0]
  def change
    create_table :weber_shipping_rates do |t|
      t.integer :min_qty
      t.integer :max_qty
      t.string :product_type
      t.float :rate

      t.timestamps
    end
  end
end
