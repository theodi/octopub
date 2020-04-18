class CreateModels < ActiveRecord::Migration[5.0]
  def change
    create_table :models do |t|
      t.string :name
      t.text :description
      t.integer :user_id
      t.belongs_to :user

      t.timestamps
    end
  end
end
