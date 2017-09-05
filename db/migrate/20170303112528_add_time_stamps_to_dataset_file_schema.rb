class AddTimeStampsToDatasetFileSchema < ActiveRecord::Migration[5.0]
  def change
    add_column(:dataset_file_schemas, :created_at, :datetime)
    add_column(:dataset_file_schemas, :updated_at, :datetime)
  end
end
