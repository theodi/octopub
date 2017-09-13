require 'rails_helper'

describe DatasetFileSchemaService do

  let(:schema_name) { Faker::Cat.name }
  let(:description) { Faker::Cat.name }
  let(:user) { create(:user) }

  context 'with a JSON table schema' do

    let(:good_schema_url) { public_s3_url_for('schemas/good-schema.json') }
    let(:good_schema_file_contents) { File.read(get_fixture_file('schemas/good-schema.json')).strip }

    before(:each) do
      @thing = DatasetFileSchemaService.create(
        name: schema_name, 
        description: description, 
        url_in_s3: good_schema_url,
        user: user
      )
    end

    context "when a user is set" do
      it "creates a new dataset file schema" do
        expect(@thing).to be_instance_of(DatasetFileSchema)
        expect(@thing.id).to_not be nil
        expect(@thing.user).to eq user
      end

      it 'creates a new dataset and updates schema as json' do
        schema_fields_from_file = DatasetFileSchemaService.parse_schema(good_schema_file_contents)
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
        DatasetFileSchemaService.populate_schema_fields_and_constraints(@thing)
        expect(@thing.schema_fields.count).to be 5
        expect(@thing.schema_fields.first.schema_constraint).to_not be nil
        expect(@thing.schema_fields.first.schema_constraint.required).to be true
        expect(@thing.schema_fields.first.schema_constraint.unique).to be true
        expect(@thing.schema_fields.last.schema_constraint).to be nil
      end
    end
  end
  
  context 'with a csv on the web schema' do
    let(:csv_schema_url) { public_s3_url_for('schemas/csv-on-the-web-schema.json') }
    let(:csv_schema_file_contents) { File.read(get_fixture_file('schemas/csv-on-the-web-schema.json')).strip }
    
    before(:each) do
      @csv_thing = DatasetFileSchemaService.create(
        name: schema_name, 
        description: description, 
        url_in_s3: csv_schema_url, 
        user: user
      )
    end

    it 'creates a new dataset and updates as csv on the web if appropriate' do
      expect(@csv_thing.schema).to be_present
      expect(JSON.parse @csv_thing.schema).to eq JSON.parse csv_schema_file_contents
      expect(@csv_thing.csv_on_the_web_schema).to be true
    end
  end
end
