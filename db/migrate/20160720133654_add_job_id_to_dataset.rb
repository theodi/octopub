class AddJobIdToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :job_id, :string
  end
end
