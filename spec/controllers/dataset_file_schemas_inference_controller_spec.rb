require 'rails_helper'

describe DatasetFileSchemasInferenceController, type: :controller do

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

      post :create, params: { name: schema_name, description: description, user_id: user.id, url_in_s3: data_file_url  }

      dataset_file_schema = DatasetFileSchema.last
      expect(dataset_file_schema.name).to eq schema_name
      expect(dataset_file_schema.description).to eq description
      expect(dataset_file_schema.user).to eq user
    end

    it "creates a dataset file schema and redirects back to index" do
      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: { name: schema_name, description: description, user_id: user.id, url_in_s3: data_file_url }
      expect(response).to redirect_to(dataset_file_schemas_path)
    end
  end
end
