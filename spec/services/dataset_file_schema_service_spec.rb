require 'rails_helper'

describe DatasetFileSchemaService do

  let(:user) { create(:user) }
  let(:infer_schema_filename) { @filename || 'schemas/infer-from/data_infer.csv' }
  let(:good_schema_file) { get_fixture_schema_file('good-schema.json') }
  let(:good_schema_file_as_json) { File.read(good_schema_file).strip }
  let(:good_schema_url) { url_with_stubbed_get_for(good_schema_file) }
  let(:schema_name) { Faker::Cat.name }
  let(:description) { Faker::Cat.name }
  
  before(:each) do
    @schema_service = DatasetFileSchemaService.new(schema_name, description, good_schema_url, user)
  end

  context "when a user is set" do

    before(:each) do
      @thing = @schema_service.create_dataset_file_schema
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
      @thing = @schema_service.create_dataset_file_schema
    end

    it 'when requested' do
      parsed_schema = DatasetFileSchemaService.get_parsed_schema_from_csv_lint(good_schema_url)
      expect(parsed_schema).to be_instance_of Csvlint::Schema
    end
  end

end
