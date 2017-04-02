require 'rails_helper'

describe DatasetFileSchemasController, type: :controller do

  before(:each) do
    @user = create(:user)
    @good_schema_url = url_with_stubbed_get_for(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'))
    allow(controller).to receive(:current_user) { @user }
  end

  describe 'can be created with organisation' do

    let(:organization) { 'my-cool-organization' }

    it "returns http success" do
      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: {
        dataset_file_schema: {
          name: schema_name, description: description, user_id: @user.id, url_in_s3: @good_schema_url, owner_username: organization
        }
      }

      dataset_file_schema = DatasetFileSchema.last
      expect(DatasetFileSchema.count).to be 1
      expect(dataset_file_schema.name).to eq schema_name
      expect(dataset_file_schema.description).to eq description
      expect(dataset_file_schema.user).to eq @user
    end
  end

  describe 'index' do
    it "returns http success" do
      get :index
      expect(response).to be_success
    end

    it "gets the right number of dataset file schemas" do
      sign_in @user
      2.times { |i| create(:dataset_file_schema, name: "Dataset File Schema #{i}", user: @user) }
      get 'index'
      expect(assigns(:dataset_file_schemas).count).to eq(2)
    end

    it "gets the right number of dataset file schemas and not someone elses" do
      other_user = create(:user, name: "User McUser 2", email: "user2@user.com")
      create(:dataset_file_schema, name: "Dataset File Schema other", user: other_user)

      sign_in @user
      2.times { |i| create(:dataset_file_schema, name: "Dataset File Schema #{i}", user: @user) }

      get 'index'
      expect(assigns(:dataset_file_schemas).count).to eq(2)
    end
  end

  describe 'show' do
    it "returns http success" do
      dataset_file_schema = create(:dataset_file_schema, user: @user)
      get :show, params: { id: dataset_file_schema.id }
      expect(response).to be_success
    end
  end

  describe 'new' do
    it "returns http success" do
      get :new
      expect(response).to be_success
    end
  end

  describe 'edit' do
    it "returns http success" do

      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      data_file = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')
      url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)

      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', url_for_schema, @user).create_dataset_file_schema

      get :edit, params: { id: dataset_file_schema.id }
      expect(response).to be_success
    end
  end

  describe 'update' do
    it "returns http success" do

      expect(FileStorageService).to receive(:push_public_object)

      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      data_file = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')
      url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)

      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', url_for_schema, @user).create_dataset_file_schema
      expect(dataset_file_schema.schema_fields).to_not be_empty
      first_field = dataset_file_schema.schema_fields.first
      old_name = first_field.name
      post :update, params: { id: dataset_file_schema.id, dataset_file_schema: {  schema_fields_attributes: [ id: first_field.id, name: 'NewName'] }}
      dataset_file_schema.reload
      expect(dataset_file_schema.schema_fields.first.name).to eq 'NewName'
      expect(response).to redirect_to(dataset_file_schema_path(dataset_file_schema))
    end

    it "sorts out the schema as json for persistence" do

      expect(FileStorageService).to receive(:push_public_object)
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      data_file = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')
      url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)

      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', url_for_schema, @user).create_dataset_file_schema
      expect(dataset_file_schema.schema_fields).to_not be_empty
      original_hash = JSON.parse(dataset_file_schema.schema)

      first_field = dataset_file_schema.schema_fields.first
      expect(SchemaField.find(first_field.id).format).to eq 'default'
      expect(SchemaField.find(first_field.id).type).to eq 'string'

      first_field_name = first_field.name
      first_field_type = first_field.type
      original_first_field_json = original_hash['fields'].first

      post :update, params: { id: dataset_file_schema.id, dataset_file_schema: {  schema_fields_attributes: [ id: first_field.id, type: 'integer'] }}

      dataset_file_schema.reload
      expect(SchemaField.find(first_field.id).type).to eq 'integer'
      expect(SchemaField.find(first_field.id).format).to eq 'default'
      expect(dataset_file_schema.schema).to include('fields')

      # Difference is type is now set, so once we know it is there, delete and hashes should be the same
      new_hash = JSON.parse(dataset_file_schema.schema)

      original_fields = original_hash['fields']
      new_field = new_hash['fields'].find {|field| field['name'] == 'Username' }
      expect(new_field['type']).to eq 'integer'
      new_field['type'] = 'string'

      expect(new_hash).to eq original_hash
      expect(response).to redirect_to(dataset_file_schema_path(dataset_file_schema))
    end
  end

  describe 'create' do
    context "returns http success" do
      let(:schema_name) { 'schema-name' }
      let(:description) { 'schema-description' }

      it "for normal schema" do
        post :create, params: {
          dataset_file_schema: {
            name: schema_name, description: description, user_id: @user.id, url_in_s3: @good_schema_url, owner_username: @user.name
          }
        }

        dataset_file_schema = DatasetFileSchema.last
        expect(dataset_file_schema.name).to eq schema_name
        expect(dataset_file_schema.description).to eq description
        expect(dataset_file_schema.user).to eq @user
        expect(dataset_file_schema.csv_on_the_web_schema).to be false
      end

      it "for csv on the web schema" do
        csv_schema_file = get_fixture_schema_file('csv-on-the-web-schema.json')
        csv_schema_file_url = url_with_stubbed_get_for(csv_schema_file)

        post :create, params: {
          dataset_file_schema: {
            name: schema_name, description: description, user_id: @user.id, url_in_s3: csv_schema_file_url, owner_username: @user.name
          }
        }
        
        dataset_file_schema = DatasetFileSchema.last
        expect(dataset_file_schema.name).to eq schema_name
        expect(dataset_file_schema.description).to eq description
        expect(dataset_file_schema.user).to eq @user
        expect(dataset_file_schema.csv_on_the_web_schema).to be true
      end
    end

    context "creates a dataset file schema and redirects back to index" do

      let(:schema_name) { 'schema-name' }
      let(:description) { 'schema-description' }
      let(:category_1) { SchemaCategory.create(name: 'cat1') }
      let(:category_2) { SchemaCategory.create(name: 'cat2') }
      let(:schema_category_ids) { [ category_1.id, category_2.id ]}

      it "without any categories" do
        post :create, params: {
          dataset_file_schema: {
            name: schema_name, description: description, user_id: @user.id, url_in_s3: @good_schema_url, owner_username: @user.name
          }
        }
        expect(response).to redirect_to(dataset_file_schemas_path)
      end

      it "with categories" do
        post :create, params: {
          dataset_file_schema: {
            name: schema_name,
            description: description,
            user_id: @user.id,
            url_in_s3: @good_schema_url,
            owner_username: @user.name,
            schema_category_ids: schema_category_ids
          }
        }
        expect(response).to redirect_to(dataset_file_schemas_path)
        dataset_file_schema = DatasetFileSchema.first
        expect(dataset_file_schema.name).to eq schema_name
        expect(dataset_file_schema.schema_category_ids).to eq schema_category_ids
        expect(dataset_file_schema.schema_categories).to eq [ category_1, category_2 ]
      end
    end
  end

  describe 'destroy' do
    it "works" do
      dataset_file_schema = create(:dataset_file_schema, user: @user)

      get :destroy, params: { id: dataset_file_schema.id }
      expect(response).to redirect_to(dataset_file_schemas_path)
      expect{ DatasetFileSchema.find(dataset_file_schema.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe 'create failure' do
    it "returns to new page if schema does not validate" do

      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: {
        dataset_file_schema: {
          name: schema_name, description: description, user_id: @user.id
        }
      }
      expect(response).to render_template("new")
    end

    it "returns to new page if no owner set" do

      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: {
        dataset_file_schema: {
          name: schema_name, description: description, user_id: @user.id, url_in_s3: @good_schema_url
        }
      }
      expect(response).to render_template("new")
    end

    it "returns to new page if no user set" do

      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: {
        dataset_file_schema: {
          name: schema_name, description: description, url_in_s3: @good_schema_url, owner_username: @user.name
        }
      }
      expect(response).to render_template("new")
    end
  end
end
