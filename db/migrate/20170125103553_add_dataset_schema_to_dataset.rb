class AddDatasetSchemaToDataset < ActiveRecord::Migration[5.0]
  def change
    add_reference :datasets, :dataset_schema, index: true
  end
end
