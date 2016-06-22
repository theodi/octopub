require 'spec_helper'

describe DatasetsController, type: :controller do

  describe 'index' do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end

    it "gets the right number of datasets" do
      5.times { |i| create(:dataset, name: "Dataset #{i}") }
      get 'index'
      expect(assigns(:datasets).count).to eq(5)
    end

    it "lists the json" do
      5.times { |i| create(:dataset, name: "Dataset #{i}") }
      get 'index', format: :json

      expect(assigns(:datasets).count).to eq(5)
      expect(response.content_type).to eq("application/json")
    end
  end

end
