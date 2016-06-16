require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  describe 'edit' do

    it 'gets a file with a particular id' do
      sign_in @user
      dataset = create(:dataset, name: "Dataset", user: @user)

      get 'edit', id: dataset.id

      expect(assigns(:dataset)).to eq(dataset)
    end

    it 'returns 404 if the user does not own a particular dataset' do
      other_user = create(:user, name: "User 2", email: "other-user@user.com")
      dataset = create(:dataset, name: "Dataset", user: other_user)

      sign_in @user

      get 'edit', id: dataset.id

      expect(response.code).to eq("404")
    end

    it 'returns 404 if the user is not signed in' do
      dataset = create(:dataset, name: "Dataset", user: @user)

      get 'edit', id: dataset.id

      expect(response.code).to eq("403")
    end

  end
end
