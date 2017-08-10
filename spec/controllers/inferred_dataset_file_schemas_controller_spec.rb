require 'rails_helper'

describe InferredDatasetFileSchemasController, type: :controller do

  let(:user) { create(:user) }
  let(:infer_schema_filename) { 'data_infer.csv' }
  let(:uuid) { 'd42c4843-bc5b-4c62-b161-a55356125b59' }
  let(:csv_storage_key) { "uploads/#{uuid}/data_infer.csv" }
  let(:infer_schema_csv_url) { url_with_stubbed_get_for_storage_key(csv_storage_key, infer_schema_filename) }

  before(:each) do
    allow(controller).to receive(:current_user) { user }
  end

  describe 'new' do
    it "returns http success" do
      get :new
      expect(response).to be_success
    end
  end

  describe 'create' do
    context "returns http success" do
      let(:schema_name) { 'schema-name' }
      let(:description) { 'schema-description' }
      let(:category_1) { SchemaCategory.create(name: 'cat1') }
      let(:category_2) { SchemaCategory.create(name: 'cat2') }
      let(:schema_category_ids) { [ category_1.id, category_2.id ]}

      it "for the user owned schema" do

        post :create, params: { inferred_dataset_file_schema: { name: schema_name, description: description, user_id: user.id, csv_url: infer_schema_csv_url, owner_username: user.name } }

        dataset_file_schema = DatasetFileSchema.last
        expect(dataset_file_schema.name).to eq schema_name
        expect(dataset_file_schema.description).to eq description
        expect(dataset_file_schema.user).to eq user
      end

      it "for the user owned schema with categories" do

        post :create, params: {
          inferred_dataset_file_schema: {
            name: schema_name,
            description: description,
            user_id: user.id,
            csv_url: infer_schema_csv_url,
            owner_username: user.name,
            schema_category_ids: schema_category_ids
          }
        }

        dataset_file_schema = DatasetFileSchema.last
        expect(dataset_file_schema.name).to eq schema_name
        expect(dataset_file_schema.description).to eq description
        expect(dataset_file_schema.user).to eq user
        expect(dataset_file_schema.schema_category_ids).to eq schema_category_ids
        expect(dataset_file_schema.schema_categories).to eq [ category_1, category_2 ]
      end

      it "for a public schema" do

        post :create, params: {
          inferred_dataset_file_schema: {
            name: schema_name,
            description: description,
            user_id: user.id,
            csv_url: infer_schema_csv_url,
            owner_username: user.name,
            restricted: false
          }
        }

        dataset_file_schema = DatasetFileSchema.last
        expect(dataset_file_schema.restricted).to eq false
      end
      
      it "for an organisation owned schema" do

        organisation = Faker::Internet.user_name

        post :create, params: { inferred_dataset_file_schema: { name: schema_name, description: description, user_id: user.id, csv_url: infer_schema_csv_url, owner_username: organisation } }

        dataset_file_schema = DatasetFileSchema.last
        expect(dataset_file_schema.name).to eq schema_name
        expect(dataset_file_schema.description).to eq description
        expect(dataset_file_schema.user).to eq user
        expect(dataset_file_schema.owner_username).to eq organisation
      end

      it "and redirects back to index" do

        organisation = Faker::Internet.user_name

        post :create, params: { inferred_dataset_file_schema: { name: schema_name, description: description, user_id: user.id, csv_url: infer_schema_csv_url, owner_username: organisation } }
        expect(response).to redirect_to(dataset_file_schemas_path)
      end
    end
  end

  describe 'create failure' do

    let(:schema_name) { Faker::Lorem.word }
    let(:description) { Faker::Lorem.sentence }

    before(:each) do
      allow(controller).to receive(:current_user) { user }
    end

    it "returns to new page if fields are missing - no file" do
      post :create, params: {
        inferred_dataset_file_schema: {
          name: schema_name, description: description, user_id: user.id
        }
      }
      expect(response).to render_template("new")
    end

    it "returns to new page if fields are missing - no name" do
      post :create, params: {
        inferred_dataset_file_schema: {
          description: description, user_id: user.id
        }
      }
      expect(response).to render_template("new")
    end

    it "returns to new page if fields are missing - no user" do
      post :create, params: {
        inferred_dataset_file_schema: {
          name: schema_name, description: description, csv_url: infer_schema_csv_url
        }
      }
      expect(response).to render_template("new")
    end

    it "returns to new page if csv does not infer a schema" do
      post :create, params: {
        inferred_dataset_file_schema: {
          name: schema_name, description: description, csv_url: url_with_stubbed_get_for_fixture_file('schemas/good-schema.json'), user_id: user.id
        }
      }
      expect(response).to render_template("new")
    end
  end
end
