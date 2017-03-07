require 'rails_helper'

describe InferredDatasetFileSchemaCreationService do

  let(:user) { create(:user) }
  let(:infer_schema_filename) { @filename || 'schemas/infer-from/data_infer.csv' }
  let(:infer_schema_csv_url) { url_with_stubbed_get_for_fixture_file(infer_schema_filename)}
  let(:uuid) { 'd42c4843-bc5b-4c62-b161-a55356125b59' }
  let(:schema_name) { Faker::Cat.name }
  let(:description) { Faker::Cat.breed }
  let(:s3_object_key) { "uploads/#{uuid}/#{schema_name.parameterize}.json" }
  let(:inferred_dataset_file_schema) { InferredDatasetFileSchema.new(name: schema_name, description: description, csv_url: infer_schema_csv_url, user_id: user.id)}

  before(:each) do
    @schema_service = InferredDatasetFileSchemaCreationService.new(inferred_dataset_file_schema)
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  context "can infer a schema" do
    it "if given a valid CSV file" do
      schema = InferredDatasetFileSchemaCreationService.infer_dataset_file_schema_from_csv(infer_schema_csv_url)
      expect(schema.get_field('id')['constraints']).to_not be_nil
    end

    it 'with international characters' do
      @filename = 'schemas/infer-from/data_infer_utf8.csv'
      schema = InferredDatasetFileSchemaCreationService.infer_dataset_file_schema_from_csv(infer_schema_csv_url)

      expect(schema.get_field('id')['type']).to eq('integer')
      expect(schema.get_field('id')['format']).to eq('default')

      expect(schema.get_field('age')['type']).to eq('integer')
      expect(schema.get_field('age')['format']).to eq('default')

      expect(schema.get_field('name')['type']).to eq('string')
      expect(schema.get_field('name')['format']).to eq('default')
    end

    it 'and upload it to S3' do
      schema = InferredDatasetFileSchemaCreationService.infer_dataset_file_schema_from_csv(infer_schema_csv_url)
      json_schema = schema.to_json

      s3_object = @schema_service.upload_inferred_schema_to_s3(json_schema, @schema_service.inferred_schema_filename(schema_name))
      expect(s3_object.key).to eq s3_object_key
    end
  end

  context "cannot infer a schema" do
    it "if given an inconsistent CSV file" do
      infer_schema_csv_url = url_with_stubbed_get_for_fixture_file('schemas/good-schema.json')
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
      expect(dataset_file_schema.url_in_s3).to eq "https://test-bucket.s3-eu-west-1.amazonaws.com/#{s3_object_key}"

      schema = JSON.parse(dataset_file_schema.schema)
      expect(schema['fields'].count).to eq 3
      expect(schema['fields'][0]['name']).to eq 'id'
    end
  end
end
