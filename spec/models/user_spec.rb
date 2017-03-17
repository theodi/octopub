# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  provider        :string
#  uid             :string
#  email           :string
#  created_at      :datetime
#  updated_at      :datetime
#  name            :string
#  token           :string
#  api_key         :string
#  org_dataset_ids :text             default([]), is an Array
#  twitter_handle  :string
#  role            :integer          default("publisher"), not null
#

require 'rails_helper'

describe User do

  context "user can have a single role" do
    it "by default, publisher" do
      user = create(:user)
      expect(user.role).to eq 'publisher'
      expect(user.publisher?).to be true
      expect(user.superuser?).to be false
      expect(user.admin?).to be false
    end

    it "as a superuser" do
      user = create(:superuser)
      expect(user.role).to eq 'superuser'
      expect(user.superuser?).to be true
      expect(user.publisher?).to be false
      expect(user.admin?).to be false
    end

    it "as an admin" do
      user = create(:admin)
      expect(user.role).to eq 'admin'
      expect(user.superuser?).to be false
      expect(user.publisher?).to be false
      expect(user.admin?).to be true
    end
  end

  context "can have dataset file schemas" do
    it "including ones created by the user" do
      user = create(:user)
      dataset_file_schema = create(:dataset_file_schema, user: user)
      expect(user.dataset_file_schemas.count).to be 1
      expect(user.dataset_file_schemas.first).to eq dataset_file_schema
    end

    it "including ones given access to" do
      user = create(:user)
      admin = create(:admin)
      dataset_file_schema = create(:dataset_file_schema, user: admin)
      user.allocated_dataset_file_schemas << dataset_file_schema
      user.reload
      expect(user.allocated_dataset_file_schemas.count).to be 1
      expect(user.allocated_dataset_file_schemas.first).to eq dataset_file_schema
    end
  end

  context "find_for_github_oauth" do

    before(:each) do
      @user_name = Faker::Name.unique.name
      @email = Faker::Internet.unique.email
      @auth = {
        "provider" => "github",
        "uid" => "1213232",
        "info" => {
          "nickname" => @user_name,
          "email" => @email
        },
        "credentials" => {
          "token" => "21312313233"
        }
      }
    end

    it "creates a user from Github oauth" do
      user = User.find_for_github_oauth(@auth)

      expect(user.name).to eq(@user_name)
      expect(user.email).to eq(@email)
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
      avatar_url = 'http://example.com/my-cool-organization.png'

      expect(Rails.configuration.octopub_admin).to receive(:user).with(@user_name.parameterize) {
        double = double(Sawyer::Resource)
        expect(double).to receive(:avatar_url) { avatar_url }
        double
      }.once

      # Load
      user.github_user
      # Lazy load
      expect(user.avatar).to eq avatar_url
    end

  end

  context "fetching datasets from other users", :vcr do

    before(:each) do
      @user = create(:user, token: ENV['GITHUB_TOKEN'])
      @user2 = create(:user)

      @dataset1 = create(:dataset, full_name: "octopub/api-sandbox", user: @user)
      @dataset2 = create(:dataset, full_name: 'octopub-data/juan-test', user: @user2)
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
