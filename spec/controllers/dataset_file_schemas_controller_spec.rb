require 'spec_helper'

describe DatasetFileSchemasController, type: :controller do
  describe 'index' do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end

    it "gets the right number of dataset file schemas" do
      5.times { |i| create(:dataset_file_schema, name: "Dataset File Schema #{i}") }
      get 'index'
      expect(assigns(:dataset_file_schemas).count).to eq(5)
    end
  end
end