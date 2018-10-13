class CreateShippingWeights < ActiveRecord::Migration
  def change
    create_table :shipping_weights do |t|
      t.string  :country
      t.string  :iso
      t.string  :state
      t.integer :weight
      t.decimal :price, :precision => 8, :scale => 2

      t.timestamps null: false
    end
  end
end
