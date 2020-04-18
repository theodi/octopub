class AddLicenceToModels < ActiveRecord::Migration[5.0]
  def change
    add_column :models, :license, :string
  end
end
