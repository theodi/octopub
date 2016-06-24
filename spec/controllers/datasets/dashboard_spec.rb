require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  describe 'dashboard' do
    it "gets the right number of datasets" do
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:github]

      5.times { |i| create(:dataset, name: "Dataset #{i}") }

      create(:dataset, user: @user)
      sign_in @user

      get 'dashboard'

      expect(assigns(:datasets).count).to eq(1)
    end

    it 'gets all user and org repos', :vcr do
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:github]

      @user = create(:user, token: ENV['GITHUB_TOKEN'])

      @dataset1 = create(:dataset, full_name: 'git-data-publisher/api-sandbox', user: @user)
      @dataset2 = create(:dataset, full_name: 'octopub-data/juan-test', user: create(:user))

      sign_in @user
      @user.send(:get_user_repos)
      get 'dashboard', refresh: true

      expect(assigns(:datasets).count).to eq(2)
    end

    it "refreshes datasets" do
      # This dataset exists
      dataset1 = create(:dataset, user: @user, repo: "dataset-1")
      allow_any_instance_of(Octokit::Client).to receive(:repository).with(dataset1.full_name)

      # This dataset has gone away
      dataset2 = create(:dataset, user: @user, repo: "dataset-2")
      allow_any_instance_of(Octokit::Client).to receive(:repository).with(dataset2.full_name) { raise Octokit::NotFound }

      sign_in @user

      get 'dashboard', refresh: true

      expect(assigns(:datasets).count).to eq(1)
      expect(assigns(:datasets).first).to eq(dataset1)
    end

    it 'gets a JSON dashboard' do
      5.times { |i| create(:dataset, name: "Dataset #{i}") }

      dataset = create(:dataset, user: @user)
      get 'dashboard', format: :json, api_key: @user.api_key

      json = JSON.parse(response.body)

      expect(json['datasets'].count).to eq(1)
      expect(json['datasets'].first['name']).to eq(dataset.name)
    end
  end
end
