class PopulateSchemaFieldsAndConstraints < ActiveRecord::Migration[5.0]
  def change

    # Rails 5 magic
    dataset_file_schemas = DatasetFileSchema.left_outer_joins(:schema_fields).where( schema_fields: { id: nil } )
    dataset_file_schemas.each { |dataset_file_schema| DatasetFileSchemaService.populate_schema_fields_and_constraints(dataset_file_schema)}
  end
end
