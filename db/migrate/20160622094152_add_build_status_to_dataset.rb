class AddBuildStatusToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :build_status, :string
  end
end
