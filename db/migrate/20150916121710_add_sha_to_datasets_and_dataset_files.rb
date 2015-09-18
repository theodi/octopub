class AddShaToDatasetsAndDatasetFiles < ActiveRecord::Migration
  def change
    add_column :dataset_files, :file_sha, :text
    add_column :dataset_files, :view_sha, :text
    add_column :datasets, :datapackage_sha, :text
  end
end
