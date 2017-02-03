require 'rails_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  describe 'new dataset' do
    it 'initializes a new dataset' do
      sign_in @user

      get 'new'
      expect(assigns(:dataset).class).to eq(Dataset)
    end
  end
end
