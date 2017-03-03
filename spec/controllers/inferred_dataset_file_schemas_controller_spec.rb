require 'rails_helper'

describe InferredDatasetFileSchemasController, type: :controller do

  let(:data_file_url) { url_with_stubbed_get_for_fixture_file('schemas/infer-from/data_infer.csv') }
  let(:user) { create(:user) }

  describe 'new' do
    it "returns http success" do
      get :new
      expect(response).to be_success
    end
  end

  describe 'create' do
    it "returns http success" do
      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: { inferred_dataset_file_schema: { name: schema_name, description: description, user_id: user.id, csv_url: data_file_url } }

      dataset_file_schema = DatasetFileSchema.last
      expect(dataset_file_schema.name).to eq schema_name
      expect(dataset_file_schema.description).to eq description
      expect(dataset_file_schema.user).to eq user
    end

    it "creates a dataset file schema and redirects back to index" do
      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: { inferred_dataset_file_schema: { name: schema_name, description: description, user_id: user.id, csv_url: data_file_url } }
      expect(response).to redirect_to(dataset_file_schemas_path)
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
          name: schema_name, description: description, csv_url: data_file_url
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
