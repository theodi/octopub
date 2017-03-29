json.set! :fields do
  json.array! @dataset_file_schema.schema_fields do |schema_field|
    json.body schema_field.name
    json.body schema_field.description
    json.body schema_field.title
    json.type schema_field.type
    json.format schema_field.format
    if schema_field.schema_constraint
      json.constraints do
        json.required schema_field.schema_constraint.required
        json.unique schema_field.schema_constraint.unique
        json.minLength schema_field.schema_constraint.min_length
        json.maxLength schema_field.schema_constraint.max_length
        json.maximum schema_field.schema_constraint.maximum
        json.minimum schema_field.schema_constraint.minimum
        json.pattern schema_field.schema_constraint.pattern
        json.type schema_field.schema_constraint.type
      end
    end
  end
end
