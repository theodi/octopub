class AddJobIdToDataset < ActiveRecord::Migration[4.2]
  def change
    add_column :datasets, :job_id, :string
  end
end
