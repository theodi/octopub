class AddBuildStatusToDataset < ActiveRecord::Migration[4.2]
  def change
    add_column :datasets, :build_status, :string
    Dataset.all.each { |d| d.build_status == "built" }
  end
end
