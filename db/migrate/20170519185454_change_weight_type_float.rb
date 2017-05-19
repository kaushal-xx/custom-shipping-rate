class ChangeWeightTypeFloat < ActiveRecord::Migration[5.0]
  def change
  	change_column :shipping_weights, :weight, :float
  end
end
