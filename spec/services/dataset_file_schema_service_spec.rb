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
    @schema_service = DatasetFileSchemaService.new(schema_name, description, good_schema_url, user, user.name)
    @thing = @schema_service.create_dataset_file_schema
  end

  context "when a user is set" do
    it "creates a new dataset file schema" do
      expect(@thing).to be_instance_of(DatasetFileSchema)
      expect(@thing.id).to_not be nil
      expect(@thing.user).to eq user
    end

    it 'creates a new dataset and updates schema as json' do
      schema_fields_from_file = DatasetFileSchemaService.parse_schema(get_json_from_url(good_schema_url))
      schema_fields_from_model = JSON.parse(@thing.schema)

      expect(@thing.schema_fields.count).to be 5

      compare_schemas_after_processing(schema_fields_from_model, schema_fields_from_file)
      expect(@thing.csv_on_the_web_schema).to be false
    end

    it 'allows retrieval of schemas from user' do
      expect(user.dataset_file_schemas).to include(@thing)
    end
  end

  context 'returns a parsed schema' do
    it 'when requested' do
      parsed_schema = DatasetFileSchemaService.get_parsed_schema_from_csv_lint(good_schema_url)
      expect(parsed_schema).to be_instance_of Csvlint::Schema
    end
  end

  context 'creates the schema structure' do
    it 'when requested' do
      schema = DatasetFileSchemaService.populate_schema_fields_and_constraints(@thing)
      expect(@thing.schema_fields.count).to be 5
      expect(@thing.schema_fields.first.schema_constraint).to_not be nil
      expect(@thing.schema_fields.first.schema_constraint.required).to be true
      expect(@thing.schema_fields.first.schema_constraint.unique).to be true
      expect(@thing.schema_fields.last.schema_constraint).to be nil
    end
  end
  context 'with a csv on the web schema' do
    let(:csv_schema_file) { get_fixture_schema_file('csv-on-the-web-schema.json') }
    let(:csv_schema_file_as_json) { File.read(csv_schema_file).strip }
    let(:csv_schema_file_url) { url_with_stubbed_get_for(csv_schema_file) }

    before(:each) do
      @csv_schema_service = DatasetFileSchemaService.new(schema_name, description, csv_schema_file_url, user, user.name)
      @csv_thing = @csv_schema_service.create_dataset_file_schema
    end

    it 'creates a new dataset and updates as csv on the web if appropriate' do
      expect(JSON.parse @csv_thing.schema).to eq JSON.parse csv_schema_file_as_json
      expect(@csv_thing.csv_on_the_web_schema).to be true
    end
  end
end
