require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  describe 'show' do

    it 'gets a file with a particular id' do
      sign_in @user
      dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])

      get 'show', id: dataset.id, format: :json

      require "pry" ; binding.pry

      json = JSON.parse(response.body)

      expect(json['id']).to eq(dataset.id)
      expect(json['name']).to eq(dataset.name)
      expect(json['dataset_files'].count).to eq(1)
    end

    it 'returns 403 if the user does not own a particular dataset' do
      other_user = create(:user, name: "User 2", email: "other-user@user.com")
      dataset = create(:dataset, name: "Dataset", user: other_user)

      sign_in @user

      get 'show', id: dataset.id

      expect(response.code).to eq("403")
    end

    it 'returns 404 if the user is not signed in' do
      dataset = create(:dataset, name: "Dataset", user: @user)

      get 'show', id: dataset.id

      expect(response.code).to eq("403")
    end

  end

end
