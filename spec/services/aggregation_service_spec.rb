require 'rails_helper'

describe AggregationService do

  let(:user) { create(:user) }
  let(:input_schema_file) { get_fixture_schema_file('disaggregated-schema.json') }
  let(:data_file_name_1) { 'disaggregated-example.csv' }
  let(:data_file_name_2) { 'disaggregated-example-2.csv' }
  let(:data_file_storage_key_1) { 'uploads/disaggregated-example.csv' }
  let(:data_file_storage_key_2) { 'uploads/disaggregated-example-2.csv' }
  let(:data_file_1) { url_with_stubbed_get_for_storage_key(data_file_storage_key_1, data_file_name_1) }
  let(:data_file_2) { url_with_stubbed_get_for_storage_key(data_file_storage_key_2, data_file_name_2) }

  let(:dataset_file_1) { create(:dataset_file, title: 'DataFile1') }
  let(:dataset_file_2) { create(:dataset_file, title: 'DataFile2') }

  let(:schema_name) { Faker::Cat.name }
  let(:input_schema) { DatasetFileSchemaService.new("#{schema_name}-input", Faker::Cat.name, input_schema_file, user, user.name).create_dataset_file_schema }

  let(:dataset_file_attributes_1) { {"id" => dataset_file_1.id, "title" => 'DataFile1', "file" => data_file_1, "storage_key" => data_file_storage_key_1 , "dataset_file_schema_id" => input_schema.id} }
  let(:dataset_file_attributes_2) { {"id" => dataset_file_2.id, "title" => 'DataFile2', "file" => data_file_2, "storage_key" => data_file_storage_key_2 , "dataset_file_schema_id" => input_schema.id} }

  let(:output_schema) { OutputSchema.create(user: user, title: "#{schema_name}-output", dataset_file_schema: input_schema)}

  before(:each) do
    dataset_file_1.update_file(dataset_file_attributes_1)
    dataset_file_2.update_file(dataset_file_attributes_2)
    expect(output_schema.output_schema_fields.count).to eq 0
    country_field = input_schema.schema_fields.find_by(name: 'Country')
    expect(country_field.present?)

    cows_field = input_schema.schema_fields.find_by(name: 'Cows')
    expect(cows_field.present?)

    chickens_field = input_schema.schema_fields.find_by(name: 'Chickens')
    expect(cows_field.present?)

    OutputSchemaField.create(output_schema: output_schema, schema_field: country_field, aggregation_type: :grouping)
    OutputSchemaField.create(output_schema: output_schema, schema_field: cows_field, aggregation_type: :totaling)
    OutputSchemaField.create(output_schema: output_schema, schema_field: chickens_field, aggregation_type: :totaling)

    # Whilst working on these tests, these are a sanity check
    expect(output_schema.dataset_file_schema).to be input_schema
    expect(input_schema.schema_fields.count).to eq 7
    expect(output_schema.totaling_schema_fields.pluck(:name)) =~ ['Cows', 'Chickens']
    expect(output_schema.grouping_schema_fields.pluck(:name)) =~ ['Country']
  end

  context "Gets the relevant dataset files" do
    it 'retrieves only files related to the input schema' do
      aggregation_service = AggregationService.new(output_schema)
      expect(output_schema.dataset_file_schema).to be input_schema
      expect(aggregation_service.get_all_relevant_datafiles.count).to be 2
      expect(aggregation_service.get_all_relevant_datafiles) =~ [dataset_file_1, dataset_file_2]
    end
  end

  context "It aggregates the relevant files" do
    it 'by the output schema' do
      aggregation_service = AggregationService.new(output_schema)
      data =  aggregation_service.aggregate_datafiles
      expect(data["England"]["Cows"]).to be 78
      expect(data["England"]["Chickens"]).to be 79
      expect(data["Scotland"]["Cows"]).to be 14
      expect(data["Scotland"]["Chickens"]).to be 9
      expect(data["Wales"]["Cows"]).to be 34
      expect(data["Wales"]["Chickens"]).to be 20
    end
  end
end
