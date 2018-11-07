class AddOwnerToModels < ActiveRecord::Migration[5.0]
  def change
    add_column :models, :owner, :string
  end
end
