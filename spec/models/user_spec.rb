# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  provider        :string(255)
#  uid             :string(255)
#  email           :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  name            :string(255)
#  token           :string(255)
#  api_key         :string(255)
#  org_dataset_ids :text             default("{}"), is an Array
#  twitter_handle  :string(255)
#

require 'spec_helper'

describe User do

  context "find_for_github_oauth" do

    before(:each) do
      @auth = {
        "provider" => "github",
        "uid" => "1213232",
        "info" => {
          "nickname" => "user-mcuser",
          "email" => "user@example.com"
        },
        "credentials" => {
          "token" => "21312313233"
        }
      }
    end

    it "creates a user from Github oauth" do
      user = User.find_for_github_oauth(@auth)

      expect(user.name).to eq("user-mcuser")
      expect(user.email).to eq("user@example.com")
      expect(user.token).to eq("21312313233")
      expect(user.api_key).to match /[a-z0-9]{20}/
    end

    it "finds a user from Github oauth" do
      user = create(:user, provider: "github", uid: "1213232")

      found_user = User.find_for_github_oauth(@auth)

      expect(found_user).to eq(user)
    end

    it "lists a user's organizations" do
      user = User.find_for_github_oauth(@auth)

      expect(user.octokit_client).to receive(:org_memberships) {
        [
          {
            name: "org1",
            role: "admin"
          },
          {
            name: "org2",
            role: "member"
          },
        ]
      }.once

      orgs = user.organizations
      user.organizations

      expect(orgs.count).to eq(1)
      expect(orgs.first[:name]).to eq("org1")
    end

    it "gets a user's github user details" do
      user = User.find_for_github_oauth(@auth)

      expect(Rails.configuration.octopub_admin).to receive(:user).with('user-mcuser') {
        {}
      }.once

      user.github_user
      user.github_user
    end

  end

  context "fetching datasets from other users", :vcr do

    before(:each) do
      @user = create(:user, token: ENV['GITHUB_TOKEN'])
      @dataset1 = create(:dataset, full_name: "octopub/api-sandbox", user: @user)
      @dataset2 = create(:dataset, full_name: 'octopub-data/juan-test', user: create(:user))
    end

    it "gets all datasets for a user's orgs" do
      expect(@user.send(:user_repos)).to eq([@dataset1.id, @dataset2.id])
    end

    it "caches dataset ids" do
      @user.send :get_user_repos
      org_dataset_ids_as_integers = @user.org_dataset_ids.map(&:to_i)
      expect(org_dataset_ids_as_integers).to eq([@dataset1.id, @dataset2.id])
    end

    it "lists datasets" do
      @user.send :get_user_repos
      expect(@user.org_datasets).to eq([@dataset1, @dataset2])
    end

    it "gets all datasets" do
      @user.send :get_user_repos
      dataset3 = create(:dataset, user: @user)
      expect(@user.all_datasets).to eq([@dataset1, @dataset2, dataset3])
    end

    it "refreshes datasets and notifies Pusher" do
      mock_client = mock_pusher('beep-beep')
      expect(mock_client).to receive(:trigger).with('refreshed', {})

      User.refresh_datasets(@user.id, 'beep-beep')

      @user.reload

      expect(@user.org_dataset_ids).to eq([@dataset1.id.to_s, @dataset2.id.to_s])
    end

  end

end
