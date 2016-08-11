require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  describe 'show' do

    it 'redirects to the api' do
      dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])

      expect(get 'show', id: dataset.id, format: :json).to redirect_to("/api/datasets/#{dataset.id}")
    end

  end

end
