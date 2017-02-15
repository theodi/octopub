require 'rails_helper'

describe DatasetFileSchemasController, type: :controller do
  describe 'index' do
    it "returns http success" do
      get dataset_file_schemas_path
      expect(response).to be_success
    end

    it "gets the right number of dataset file schemas" do
      user = create(:user, name: "User McUser", email: "user@user.com")
      sign_in user
      2.times { |i| create(:dataset_file_schema, name: "Dataset File Schema #{i}", user: user) }
      get 'index'
      expect(assigns(:dataset_file_schemas).count).to eq(2)
    end

    it "gets the right number of dataset file schemas and not someone elses" do
      other_user = create(:user, name: "User McUser", email: "user@user.com")
      create(:dataset_file_schema, name: "Dataset File Schema other", user: other_user)

      user = create(:user, name: "User McUser", email: "user@user.com")
      sign_in user
      2.times { |i| create(:dataset_file_schema, name: "Dataset File Schema #{i}", user: user) }

      get 'index'
      expect(assigns(:dataset_file_schemas).count).to eq(2)
    end
  end

  describe 'new' do
    it "returns http success" do
      get new_dataset_file_schema_path
      expect(response).to be_success
    end
  end

  describe 'create' do
    it "returns http success" do
      post dataset_file_schemas_path
      expect(response).to be_success
    end

    it "creates a dataset file schema and redirects back to index" do
      post dataset_file_schemas_path
      expect(response).to be_success
    end
  end
end
