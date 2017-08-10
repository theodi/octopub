require 'rails_helper'
require 'support/odlifier_licence_mock'

describe DatasetsController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'odlifier licence mock'

  before(:each) do
    @user = create(:user)
    @other_user = create(:user, name: "User McUser 2", email: "user2@user.com")
    @my_schema = create(:dataset_file_schema, name: "My Schema", user: @user)
    @private_schema = create(:dataset_file_schema, name: "Private Schema", user: @other_user)
  end

  describe 'edit' do

    it 'gets a file with a particular id' do
      sign_in @user
      dataset = create(:dataset, name: "Dataset", user: @user)
      get :edit, params: { id: dataset.id }

      expect(assigns(:dataset)).to eq(dataset)
    end

    it "lists the user's schemas" do
      sign_in @user
      dataset = create(:dataset, name: "Dataset", user: @user)
      get :edit, params: { id: dataset.id }
      expect(assigns(:dataset_file_schemas).count).to eq(1)
    end

    it "lists public schemas as well" do
      create(:dataset_file_schema, name: "Public Schema", user: @other_user, restricted: false)
      sign_in @user
      dataset = create(:dataset, name: "Dataset", user: @user)
      get :edit, params: { id: dataset.id }
      expect(assigns(:dataset_file_schemas).count).to eq(2)
    end


    # TODO can't see how this ever works without organizations!

    # it 'allows a user to get a dataset that belongs to one of their organizations' do
    #   sign_in @user
    #   expect(User).to receive(:find) { @user }

    #   dataset1 = create(:dataset, name: "Dataset", user: @user)
    #   dataset2 = create(:dataset, name: "Dataset")

    #   expect(@user).to receive(:all_dataset_ids) { [dataset1.id, dataset2.id] }

    #   get :edit, params: { id: dataset2.id }

    #   expect(assigns(:dataset)).to eq(dataset2)
    # end

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
