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

    it "redirects to API for json version" do
      expect(get 'index', format: :json).to redirect_to('/api/datasets')
    end
  end

end
