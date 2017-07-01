class AddDescriptionToDatasetFile < ActiveRecord::Migration[4.2]
  def change
    add_column :dataset_files, :description, :text
  end
end
