require 'rails_helper'

describe DatasetsController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  describe 'edit' do

    it 'gets a file with a particular id' do
      sign_in @user
      dataset = create(:dataset, name: "Dataset", user: @user)

      get :edit, params: { id: dataset.id }

      expect(assigns(:dataset)).to eq(dataset)
    end

    it 'allows a user to get a dataset that belongs to one of their organizations' do
      sign_in @user
      expect(User).to receive(:find) { @user }

      dataset1 = create(:dataset, name: "Dataset", user: @user)
      dataset2 = create(:dataset, name: "Dataset")

      expect(@user).to receive(:all_dataset_ids) { [dataset1.id, dataset2.id] }

      get :edit, params: { id: dataset2.id }

      expect(assigns(:dataset)).to eq(dataset2)
    end

    it 'returns 403 if the user does not own a particular dataset' do
      other_user = create(:user, name: "User 2", email: "other-user@user.com")
      dataset = create(:dataset, name: "Dataset", user: other_user)

      sign_in @user

      get :edit, params: { id: dataset.id }

      expect(response.code).to eq("403")
    end

    it 'returns 404 if the user is not signed in' do
      dataset = create(:dataset, name: "Dataset", user: @user)

      get :edit, params: { id: dataset.id }

      expect(response.code).to eq("403")
    end

  end
end
