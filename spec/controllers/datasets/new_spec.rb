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

  describe 'new dataset' do

    it 'initializes a new dataset' do
      sign_in @user
      get 'new'
      expect(assigns(:dataset).class).to eq(Dataset)
    end

    it "lists the user's schemas" do
      sign_in @user
      get 'new'
      expect(assigns(:dataset_file_schemas).count).to eq(1)
    end

    it "lists public schemas as well" do
      create(:dataset_file_schema, name: "Public Schema", user: @other_user, restricted: false)
      sign_in @user
      get 'new'
      expect(assigns(:dataset_file_schemas).count).to eq(2)
    end


  end
end
