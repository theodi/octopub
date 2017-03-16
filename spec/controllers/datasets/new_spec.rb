require 'rails_helper'
require 'support/odlifier_licence_mock'

describe DatasetsController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'odlifier licence mock'

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
