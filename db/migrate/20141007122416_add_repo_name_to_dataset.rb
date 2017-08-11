class AddRepoNameToDataset < ActiveRecord::Migration[4.2]
  def change
    add_column :datasets, :repo, :string
  end
end
