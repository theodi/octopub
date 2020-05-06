class AddValidationToDatasetFile < ActiveRecord::Migration[5.0]
  def change
    add_column :dataset_files, :validation, :boolean
  end
end
