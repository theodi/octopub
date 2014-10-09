class AddFiles < ActiveRecord::Migration
  def change
    create_table :dataset_files do |t|
      t.string :title
      t.string :filename
      t.string :mediatype
      t.integer :dataset_id

      t.timestamps
    end
  end
end
