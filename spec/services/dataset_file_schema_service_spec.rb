require 'rails_helper'

describe DatasetFileSchemaService do

  let(:user) { create(:user) }
  let(:infer_schema_filename) { @filename || 'schemas/infer-from/data_infer.csv' }
  let(:good_schema_file) { get_fixture_schema_file('good-schema.json') }
  let(:good_schema_file_as_json) { File.read(good_schema_file).strip }
  let(:good_schema_url) { url_with_stubbed_get_for(good_schema_file) }
  let(:infer_schema_csv_url) { url_with_stubbed_get_for_fixture_file(infer_schema_filename)}

  before(:each) do
    @schema_service = DatasetFileSchemaService.new
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
  end

  context "cannot infer a schema" do
    it "if given an inconsistent CSV file" do
      @filename = 'schemas/good-schema.json'
      expect { @schema_service.infer_dataset_file_schema_from_csv(infer_schema_csv_url) }.to raise_error CSV::MalformedCSVError
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
