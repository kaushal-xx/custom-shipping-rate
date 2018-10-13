class AddCompanyNameToDraftOrder < ActiveRecord::Migration
  def change
    add_column :draft_orders, :company_name, :string
  end
end
