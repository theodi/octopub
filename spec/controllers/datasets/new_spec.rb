require 'rails_helper'

describe DatasetsController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do

  before(:each) do
    @user = create(:user)
  end

  describe 'new dataset' do
    it 'initializes a new dataset' do
      sign_in @user

      get 'new'
      expect(assigns(:dataset).class).to eq(Dataset)
    end
  end
end
