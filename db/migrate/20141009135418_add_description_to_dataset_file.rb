class AddDescriptionToDatasetFile < ActiveRecord::Migration
  def change
    add_column :dataset_files, :description, :text
  end
end
