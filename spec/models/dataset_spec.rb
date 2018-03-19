# == Schema Information
#
# Table name: datasets
#
#  id                :integer          not null, primary key
#  name              :string
#  url               :string
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#  repo              :string
#  description       :text
#  publisher_name    :string
#  publisher_url     :string
#  license           :string
#  frequency         :string
#  datapackage_sha   :text
#  owner             :string
#  owner_avatar      :string
#  build_status      :string
#  full_name         :string
#  certificate_url   :string
#  job_id            :string
#  publishing_method :integer          default("github_public"), not null
#  published_status: :boolean          default: false
#

require 'rails_helper'
require 'support/odlifier_licence_mock'

describe Dataset, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'odlifier licence mock'

  before(:each) do
    @user = create(:user)
    allow_any_instance_of(Octokit::Client).to receive(:repository?) { false }
    allow(RepoService).to receive(:prepare_repo)
    Sidekiq::Testing.inline!
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  it "creates a valid public dataset" do
    dataset = create(:dataset, user: @user)
    expect(dataset.publishing_method).to eq :github_public.to_s
    expect(dataset).to be_valid
    expect(dataset.restricted).to be false
  end

  it "returns an error if the repo already exists" do
    expect_any_instance_of(Octokit::Client).to receive(:repository?).with("#{@user.github_username}/my-awesome-dataset") { true }
    dataset = build(:dataset, user: @user)
    expect(dataset).to_not be_valid
  end

  it "creates a repo in Github" do

    name = "My Awesome Dataset"
    html_url = "http://github.com/#{@user.name}/#{name.parameterize}"

    dataset = build(:dataset, :with_callback, user: @user, name: name)

    obj = double(GitData)
    expect(GitData).to receive(:create).with(@user.github_username, name, restricted: false, client: a_kind_of(Octokit::Client)) {

      expect(obj).to receive(:add_file) { nil }
      expect(obj).to receive(:save) { nil }
      expect(obj).to receive(:html_url) { html_url }
      expect(obj).to receive(:name) { name.parameterize }
      expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
      obj
    }
    allow(GitData).to receive(:find).with(@user.github_username, name, client: a_kind_of(Octokit::Client)) {
      obj
    }

    jekyll_service = JekyllService.new(dataset, nil)

    allow_any_instance_of(Dataset).to receive(:complete_publishing)

    dataset.save
    CreateRepository.new.perform(dataset.id)
    dataset.reload

    expect(dataset.repo).to eq(name.parameterize)
    expect(dataset.url).to eq(html_url)
  end

  it "creates a repo with an organization" do
    name = "My Awesome Dataset"
    dataset = build(:dataset, :with_callback, user: @user, name: name, owner: "my-cool-organization")
    html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
    obj = double(GitData)
    expect(GitData).to receive(:create).with('my-cool-organization', name, restricted: false, client: a_kind_of(Octokit::Client)) {

      expect(obj).to receive(:html_url) { html_url }
      expect(obj).to receive(:name) { name.parameterize }
      expect(obj).to receive(:full_name) { "my-cool-organization/#{name.parameterize}" }
      obj
    }
    allow(GitData).to receive(:find).with('my-cool-organization', name, client: a_kind_of(Octokit::Client)) {
      obj
    }

    expect_any_instance_of(JekyllService).to receive(:add_files_to_repo_and_push_to_github)
    expect_any_instance_of(Dataset).to receive(:complete_publishing)

    dataset.save
    CreateRepository.new.perform(dataset.id)
  end

  it "completes publishing" do
    dataset = build(:dataset)
    expect(RepoService).to receive(:fetch_repo)
    expect(dataset).to receive(:set_owner_avatar)
    expect(dataset).to receive(:publish_public_views).with(true)
    # expect(dataset).to receive(:send_success_email)
    expect_any_instance_of(SendTweetService).to receive(:perform)
    dataset.complete_publishing
  end

  it "deletes a repo in github if it should have one" do
    dataset = create(:dataset, user: @user, owner: "foo-bar")
    repo = double(GitData)
    expect(RepoService).to receive(:fetch_repo) { repo }
    expect(repo).to receive(:delete)

    dataset.destroy
    expect{ Dataset.find(dataset.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "deletes a repo in github if it should have one but cannot find it" do
    dataset = create(:dataset, user: @user, owner: "foo-bar")
    expect(dataset).to receive(:actual_repo).and_raise(Octokit::NotFound)
    expect_any_instance_of(JekyllService).to_not receive(:update_dataset_in_github)

    dataset.destroy
    expect{ Dataset.find(dataset.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "deletes dataset without a repository" do
    dataset = create(:dataset, user: @user, owner: "foo-bar", publishing_method: :local_private)
    repo = double(GitData)
    expect(RepoService).to_not receive(:fetch_repo) { repo }
    expect(repo).to_not receive(:delete)
    dataset.destroy
    expect{ Dataset.find(dataset.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "tests the robustness of the url evaluate response code method" do
    {
      'www.deadurl.com' => false,
      'http://www.deadurl.com' => false,
      'www.deadurl.com/example.csv' => false,
      'http://www.deadurl.com/example.csv' => true
    }.each_pair do |url, result|

      it "should parse #{url} correctly in eval_response_code" do
        stub_request(:any, url)
        expect(Dataset.eval_response_code?(url)).to eq result
      end
    end
  end

  it "adds a deprecated date value to datasets when URL does not return 200" do
    stub_request(:any, "www.deadurl.com/example.csv").
        to_return(status: [404, "Resource Unavailable"])
    deprecated_dataset = create(:dataset, user: @user)
    deprecated_dataset.update_column(:url, "http://www.deadurl.com/example.csv")
    Dataset.check_urls
    expect(Dataset.find(deprecated_dataset.id).deprecated_resource).to be true
  end

  it "leaves deprecated date field nil when URL returns 200" do
    stub_request(:any, "www.liveurl.com/example.csv").
        to_return(status: [200, "Resource Available"])
    dataset = create(:dataset, user: @user)
    dataset.update_column(:url, "http://www.liveurl.com/example.csv")
    Dataset.check_urls
    expect(Dataset.find(dataset.id).deprecated_resource).to be false
  end

  it "sets the user's avatar" do
    dataset = create(:dataset, user: @user)
    expect(@user).to receive(:avatar) { 'http://example.com/avatar.png' }

    dataset.send(:set_owner_avatar)
    expect(dataset.owner_avatar).to eq('http://example.com/avatar.png')
  end

  it "sets the user's avatar even if owner == user" do
    dataset = create(:dataset, user: @user, owner: @user.github_username)
    expect(@user).to receive(:avatar) { 'http://example.com/avatar.png' }

    dataset.send(:set_owner_avatar)
    expect(dataset.owner_avatar).to eq('http://example.com/avatar.png')
  end

  it "sets the owner's avatar" do
    dataset = create(:dataset, user: @user, owner: 'my-cool-organization')
    expect(Rails.configuration.octopub_admin).to receive(:organization).with('my-cool-organization') {
      double = double(Sawyer::Resource)
      expect(double).to receive(:avatar_url) { 'http://example.com/my-cool-organization.png' }
      double
    }

    dataset.send(:set_owner_avatar)
    expect(dataset.owner_avatar).to eq('http://example.com/my-cool-organization.png')
  end

  it "generates a path" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect(dataset.path("filename")).to eq("filename")
    expect(dataset.path("filename", "folder")).to eq("folder/filename")
  end

  it "generates the correct config" do
    dataset = build(:dataset, frequency: "weekly")
    config = YAML.load dataset.config

    expect(config["update_frequency"]).to eq("weekly")
  end

  context "creating restricted datasets" do
    it "creates a valid dataset" do
      dataset = create(:dataset, name: "My Awesome Dataset",
                       description: "An awesome dataset",
                       publisher_name: "Awesome Inc",
                       publisher_url: "http://awesome.com",
                       license: "OGL-UK-3.0",
                       frequency: "One-off",
                       user: @user,
                       publishing_method: :github_private)

      expect(dataset).to be_valid
      expect(dataset.restricted).to be true
    end

    it "creates a private repo in Github" do
      mock_client = mock_pusher('beep-beep')
      name = "My Awesome Dataset"
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"

      dataset = build(:dataset, :with_callback, user: @user, name: name, publishing_method: :github_private)
      obj = double(GitData)
      expect(GitData).to receive(:create).with(@user.github_username, name, restricted: true, client: a_kind_of(Octokit::Client)) {
        expect(obj).to receive(:html_url) { html_url }
        expect(obj).to receive(:name) { name.parameterize }
        expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
        obj
      }
      allow(GitData).to receive(:find).with(@user.github_username, name, client: a_kind_of(Octokit::Client)) {
        obj
      }

      expect_any_instance_of(JekyllService).to receive(:add_files_to_repo_and_push_to_github)
      expect_any_instance_of(Dataset).to receive(:complete_publishing)

      dataset.report_status('beep-beep')
      dataset.reload

      expect(dataset.repo).to eq(name.parameterize)
      expect(dataset.url).to eq(html_url)
    end

    it "creates a private local repo" do
      mock_client = mock_pusher('beep-beep')
      name = "My Awesome Dataset"
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"

      dataset = build(:dataset, :with_callback, user: @user, name: name, publishing_method: :local_private)

      expect(GitData).to_not receive(:create)
      expect(GitData).to_not receive(:find)
      expect_any_instance_of(JekyllService).to_not receive(:add_files_to_repo_and_push_to_github)
      expect_any_instance_of(Dataset).to_not receive(:complete_publishing)

      expect_any_instance_of(DatasetMailer).to receive(:success)
      dataset.report_status('beep-beep')
      dataset.reload

      expect(dataset.repo).to be_nil
      expect(dataset.url).to be_nil
    end

    it "can make a private repo public" do
      mock_client = mock_pusher('beep-beep')


      # Create dataset

      name = "My Awesome Dataset"
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
      dataset = build(:dataset, :with_callback, user: @user, name: name, publishing_method: :github_private)
      obj = double(GitData)
      expect(GitData).to receive(:create).with(@user.github_username, name, restricted: true, client: a_kind_of(Octokit::Client)) {
        expect(obj).to receive(:add_file).once { nil }
        expect(obj).to receive(:save) { nil }
        expect(obj).to receive(:html_url) { html_url }
        expect(obj).to receive(:name) { name.parameterize }
        expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
        expect(obj).to receive(:make_public)
        obj
      }
      allow(GitData).to receive(:find).with(@user.github_username, name, client: a_kind_of(Octokit::Client)) {
        obj
      }

      expect_any_instance_of(Dataset).to receive(:complete_publishing)

      dataset.report_status('beep-beep')

      # Update dataset and make public
      updated_dataset = Dataset.find(dataset.id)
      expect(updated_dataset.restricted).to be true

      expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github).once
      expect_any_instance_of(JekyllService).to receive(:create_public_views).once
      updated_dataset.publishing_method = :github_public#!# = false

      updated_dataset.save
      expect(updated_dataset.restricted).to be false

      skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)
    end
  end

  context "prepublishing a dataset" do
    it "creates a dataset with a published status of false" do
      dataset = create(:dataset, user: @user)
      expect(dataset.published_status).to eq(false)
    end
  end

  context "returns a list of schemas used" do
    it "with an empty string when none" do
      dataset = build(:dataset, user: @user,
          dataset_files: [ build(:dataset_file)])
      expect(dataset.schema_names).to eq ""
    end

    it "with a name if one" do
      schema_name = Faker::Name.unique.name
      dataset = build(:dataset, user: @user,
          dataset_files: [ build(:dataset_file, dataset_file_schema: build(:dataset_file_schema, name: schema_name))])
      expect(dataset.schema_names).to eq schema_name
    end

    it "with a list if many" do
      schema_name = Faker::Name.unique.name
      schema_name_2 = Faker::Name.unique.name
      dataset = build(:dataset, user: @user,
          dataset_files: [
            build(:dataset_file, dataset_file_schema: build(:dataset_file_schema, name: schema_name)),
            build(:dataset_file, dataset_file_schema: build(:dataset_file_schema, name: schema_name_2)),
            build(:dataset_file),
          ]
      )
      expect(dataset.schema_names).to eq "#{schema_name}, #{schema_name_2}"
    end
  end
end
