class AddLicenceToModels < ActiveRecord::Migration[5.0]
  def change
    add_column :models, :licence, :string
  end
end
