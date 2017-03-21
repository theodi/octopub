class AddAllocatedDatasetFileSchemasUsersTable < ActiveRecord::Migration[5.0]
  def change
   create_table :allocated_dataset_file_schemas_users, id: false do |t|
      t.belongs_to :dataset_file_schema, index: { name: "allocated_dataset_file_schema_index"}
      t.belongs_to :user, index: { name: "allocated_user_index"}
    end
  end
end
