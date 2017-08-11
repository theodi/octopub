class CreateDatasets < ActiveRecord::Migration[4.2]
  def change
    create_table :datasets do |t|
      t.string :name
      t.string :url
      t.belongs_to :user

      t.timestamps
    end
  end
end
