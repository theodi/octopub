class AddRepoNameToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :repo, :string
  end
end
