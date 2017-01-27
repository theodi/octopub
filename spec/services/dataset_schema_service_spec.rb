require 'spec_helper'

describe DatasetSchemaService do

  it 'updates with schema as json' do
    example_schema_uri = 'http://my-schemas.org/1234/schema.json'
    dataset_file_schema = DatasetFileSchema.new(schema: example_schema_uri)
    good_schema_file_as_json = File.read(File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json'))
    allow_any_instance_of(DatasetSchemaService).to receive(:read_file_with_utf_8).and_return(good_schema_file_as_json)

    schema_service = DatasetSchemaService.new(dataset_file_schema)
    schema_service.update_dataset_file_schema_with_json_schema
    expect(dataset_file_schema.schema).to eq good_schema_file_as_json
  end
end