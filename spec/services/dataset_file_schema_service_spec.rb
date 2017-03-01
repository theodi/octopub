require 'rails_helper'

describe DatasetFileSchemaService do

  let(:user) { create(:user) }
  let(:infer_schema_filename) { @filename || 'schemas/infer-from/data_infer.csv' }
  let(:good_schema_file) { get_fixture_schema_file('good-schema.json') }
  let(:good_schema_file_as_json) { File.read(good_schema_file).strip }
  let(:good_schema_url) { url_with_stubbed_get_for(good_schema_file) }
  let(:infer_schema_csv_url) { url_with_stubbed_get_for_fixture_file(infer_schema_filename)}
  let(:uuid) { 'd42c4843-bc5b-4c62-b161-a55356125b59' }
  let(:schema_name) { Faker::Cat.name }
  let(:s3_object_key) { "uploads/#{uuid}/#{schema_name.parameterize}.json" }

  before(:each) do
    @schema_service = DatasetFileSchemaService.new
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  context "can infer a schema" do
    it "if given a valid CSV file" do
      schema = @schema_service.infer_dataset_file_schema_from_csv(infer_schema_csv_url)
      expect(schema.get_field('id')['constraints']).to_not be_nil
    end

    it 'with international characters' do
      @filename = 'schemas/infer-from/data_infer_utf8.csv'
      schema = @schema_service.infer_dataset_file_schema_from_csv(infer_schema_csv_url)

      expect(schema.get_field('id')['type']).to eq('integer')
      expect(schema.get_field('id')['format']).to eq('default')

      expect(schema.get_field('age')['type']).to eq('integer')
      expect(schema.get_field('age')['format']).to eq('default')

      expect(schema.get_field('name')['type']).to eq('string')
      expect(schema.get_field('name')['format']).to eq('default')
    end

    it 'and upload it to S3' do
      schema = @schema_service.infer_dataset_file_schema_from_csv(infer_schema_csv_url)
      json_schema = schema.to_json

      expect_any_instance_of(Aws::S3::Object).to receive(:put).with({ body: json_schema })
      s3_object = @schema_service.upload_inferred_schema_to_s3(json_schema, @schema_service.inferred_schema_filename(schema_name))
      expect(s3_object.key).to eq s3_object_key
    end
  end

  context "cannot infer a schema" do
    it "if given an inconsistent CSV file" do
      @filename = 'schemas/good-schema.json'
      expect { @schema_service.infer_dataset_file_schema_from_csv(infer_schema_csv_url) }.to raise_error CSV::MalformedCSVError
    end
  end

  context 'can infer and create a schema' do
    it 'from a valid csv file' do
      description = Faker::Cat.breed
      expect(DatasetFileSchema.count).to be 0
      @schema_service.infer_and_create_dataset_file_schema(infer_schema_csv_url, user, schema_name, description)
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

  context "when no user is set" do

    before(:each) do
      @thing = @schema_service.create_dataset_file_schema('schema name', 'schema description', good_schema_url)
    end

    it "creates a new dataset file schema" do
      expect(@thing).to be_instance_of(DatasetFileSchema)
      expect(@thing.id).to_not be nil
      expect(@thing.user).to be nil
    end

    it 'creates a new dataset and updates schema as json' do
      expect(@thing.schema).to eq good_schema_file_as_json
    end
  end

  context "when a user is set" do

    before(:each) do
      @thing = @schema_service.create_dataset_file_schema('schema name', 'schema description', good_schema_url, user)
    end

    it "creates a new dataset file schema" do
      expect(@thing).to be_instance_of(DatasetFileSchema)
      expect(@thing.id).to_not be nil
      expect(@thing.user).to be user
    end

    it 'creates a new dataset and updates schema as json' do
      expect(@thing.schema).to eq good_schema_file_as_json
    end

    it 'allows retrieval of schemas from user' do
      expect(user.dataset_file_schemas).to include(@thing)
    end
  end

  context 'returns a parsed schema' do

    before(:each) do
      @thing = @schema_service.create_dataset_file_schema('schema name', 'schema description', good_schema_url)
    end

    it 'when requested' do
      parsed_schema = DatasetFileSchemaService.get_parsed_schema_from_csv_lint(good_schema_url)
      expect(parsed_schema).to be_instance_of Csvlint::Schema
    end
  end

end
