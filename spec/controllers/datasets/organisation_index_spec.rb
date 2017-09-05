require 'rails_helper'

describe DatasetsController, type: :controller do
  it 'gets all the organisation repos' do
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:github]

    @user = create(:user, token: ENV['GITHUB_TOKEN'])

    @dataset1 = create(:dataset, full_name: 'octopub/api-sandbox', owner: 'octopub', user: @user)
    @dataset2 = create(:dataset, full_name: 'octopub-data/juan-test', owner: 'octopub', user: create(:user))

    sign_in @user
    get :organisation_index, params: { organisation_name: 'octopub' }

    expect(assigns(:datasets).count).to eq(2)
  end
end