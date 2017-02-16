require 'rails_helper'

describe DatasetFileSchemasController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
    @good_schema_url = url_with_stubbed_get_for(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'))
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

      post :create, params: {
        dataset_file_schema: {
          name: schema_name, description: description, user_id: @user.id, url_in_s3: @good_schema_url
        }
      }

      dataset_file_schema = DatasetFileSchema.last
      expect(dataset_file_schema.name).to eq schema_name
      expect(dataset_file_schema.description).to eq description
      expect(dataset_file_schema.user).to eq @user
    end

    it "creates a dataset file schema and redirects back to index" do
      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: {
        dataset_file_schema: {
          name: schema_name, description: description, user_id: @user.id, url_in_s3: @good_schema_url
        }
      }
      expect(response).to redirect_to(dataset_file_schemas_path)
    end
  end

  describe 'create failure' do
  #  render_views

    before(:each) do
      allow(controller).to receive(:current_user) { @user }
    end

    it "returns to new page if schema does not validate" do

      schema_name = 'schema-name'
      description = 'schema-description'

      post :create, params: {
        dataset_file_schema: {
          name: schema_name, description: description, user_id: @user.id
        }
      }
      expect(response).to render_template("new")
  #    expect(response.body).to match /You must have a schema file/
    end

  end
end
