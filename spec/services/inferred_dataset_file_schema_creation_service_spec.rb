require 'rails_helper'
require 'webmock/rspec'

describe InferredDatasetFileSchemaCreationService do

  let(:user) { create(:user) }

  let(:uuid) { SecureRandom.uuid }

  let(:csv_storage_key) { "uploads/#{uuid}/data_infer.csv" }
  let(:infer_schema_csv_url) { url_with_stubbed_get_for_storage_key(csv_storage_key, 'data_infer.csv') }

  let(:schema_name) { Faker::Cat.name }
  let(:description) { Faker::Cat.breed }
  let(:schema_filename) { "#{schema_name.parameterize}.json" }
  let(:s3_object_key) { "uploads/#{uuid}/#{schema_filename}" }
  let(:inferred_dataset_file_schema) { InferredDatasetFileSchema.new(name: schema_name, description: description, csv_url: infer_schema_csv_url, user_id: user.id, owner_username: user.name)}

  before(:each) do
    @schema_service = InferredDatasetFileSchemaCreationService.new(inferred_dataset_file_schema)
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  context "can infer a schema" do
    it "if given a valid CSV file" do
      schema = InferredDatasetFileSchemaCreationService.infer_dataset_file_schema_from_csv(infer_schema_csv_url)
      expect(schema.get_field('id')['constraints']).to_not be_nil
    end

    it "if given a valid CSV file with empty fields" do
      @filename = 'data_infer_empty_cells.csv'
      csv_storage_key = "uploads/#{uuid}/#{@filename}"
      url = url_with_stubbed_get_for_storage_key(csv_storage_key, @filename)
      schema = InferredDatasetFileSchemaCreationService.infer_dataset_file_schema_from_csv(url)
      expect(schema.get_field('height')['constraints']).to_not be_nil
    end

    it 'with international characters' do
      @filename = 'data_infer_utf8.csv'
      csv_storage_key = "uploads/#{uuid}/#{@filename}"
      url = url_with_stubbed_get_for_storage_key(csv_storage_key, @filename)
      schema = InferredDatasetFileSchemaCreationService.infer_dataset_file_schema_from_csv(url)

      expect(schema.get_field('id')['type']).to eq('integer')
      expect(schema.get_field('id')['format']).to eq('default')

      expect(schema.get_field('age')['type']).to eq('integer')
      expect(schema.get_field('age')['format']).to eq('default')

      expect(schema.get_field('name')['type']).to eq('string')
      expect(schema.get_field('name')['format']).to eq('default')
    end
  end

  context "cannot infer a schema" do
    it "if given an inconsistent CSV file" do
      duff_csv_filename = 'datapackage.json'
      csv_storage_key = "uploads/#{uuid}/#{duff_csv_filename}"
      infer_schema_csv_url = url_with_stubbed_get_for_storage_key(csv_storage_key, duff_csv_filename)
      expect { InferredDatasetFileSchemaCreationService.infer_dataset_file_schema_from_csv(infer_schema_csv_url) }.to raise_error CSV::MalformedCSVError
    end
  end

  context 'can infer and create a schema' do
    it 'from a valid csv file' do

      expect(DatasetFileSchema.count).to be 0
      @schema_service.perform
      expect(DatasetFileSchema.count).to be 1
      dataset_file_schema = DatasetFileSchema.first
      expect(dataset_file_schema.user).to eq user
      expect(dataset_file_schema.name).to eq schema_name
      expect(dataset_file_schema.description).to eq description
      expect(dataset_file_schema.url_in_s3).to eq "https://example.org/uploads/1234/#{schema_filename}"

      schema = JSON.parse(dataset_file_schema.schema)
      expect(schema['fields'].count).to eq 3
      expect(schema['fields'][0]['name']).to eq 'id'
    end

    it 'from a valid csv file and creates the schema field and constraints' do
      @schema_service.perform

      dataset_file_schema = DatasetFileSchema.first
      schema = JSON.parse(dataset_file_schema.schema)
      expect(schema['fields'].count).to eq 3
      expect(schema['fields'][0]['name']).to eq 'id'

      expect(dataset_file_schema.schema_fields.count).to eq 3
      expect(dataset_file_schema.schema_fields.first.name).to eq 'id'
    end
  end
end
