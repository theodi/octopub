require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  describe 'files' do

    it 'gets files for a dataset with a particular id' do
      set_api_key(@user)

      dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv'),
        create(:dataset_file, filename: 'test-data-2.csv')
      ])

      get 'files', id: dataset.id, format: :json

      json = JSON.parse(response.body)

      expect(json.count).to eq(2)
    end

    it 'returns 403 if the user does not own a particular dataset' do
      other_user = create(:user, name: "User 2", email: "other-user@user.com")
      dataset = create(:dataset, name: "Dataset", user: other_user)

      set_api_key(@user)

      get 'files', id: dataset.id

      expect(response.code).to eq("403")
    end

    it 'returns 404 if the user is not signed in' do
      dataset = create(:dataset, name: "Dataset", user: @user)

      get 'files', id: dataset.id

      expect(response.code).to eq("403")
    end

  end

end
