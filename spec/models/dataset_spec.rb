# == Schema Information
#
# Table name: datasets
#
#  id              :integer          not null, primary key
#  name            :string
#  url             :string
#  user_id         :integer
#  created_at      :datetime
#  updated_at      :datetime
#  repo            :string
#  description     :text
#  publisher_name  :string
#  publisher_url   :string
#  license         :string
#  frequency       :string
#  datapackage_sha :text
#  owner           :string
#  owner_avatar    :string
#  build_status    :string
#  full_name       :string
#  certificate_url :string
#  job_id          :string
#  restricted      :boolean          default(FALSE)
#

require 'rails_helper'

describe Dataset, vcr: { :match_requests_on => [:host, :method] } do

  before(:each) do
    @user = create(:user, name: "user-mcuser", email: "user@user.com")
    allow_any_instance_of(Octokit::Client).to receive(:repository?) { false }
  end

  it "creates a valid public dataset" do
    dataset = create(:dataset, name: "My Awesome Dataset",
                     description: "An awesome dataset",
                     publisher_name: "Awesome Inc",
                     publisher_url: "http://awesome.com",
                     license: "OGL-UK-3.0",
                     frequency: "One-off",
                     user: @user)

    expect(dataset).to be_valid
    expect(dataset.restricted).to be false
  end

  it "returns an error if the repo already exists" do
    expect_any_instance_of(Octokit::Client).to receive(:repository?).with("user-mcuser/my-awesome-dataset") { true }

    dataset = build(:dataset, name: "My Awesome Dataset",
                     description: "An awesome dataset",
                     publisher_name: "Awesome Inc",
                     publisher_url: "http://awesome.com",
                     license: "OGL-UK-3.0",
                     frequency: "One-off",
                     user: @user)

    expect(dataset).to_not be_valid
  end

  it "creates a repo in Github" do
    name = "My Awesome Dataset"
    html_url = "http://github.com/#{@user.name}/#{name.parameterize}"

    dataset = build(:dataset, :with_callback, user: @user, name: name)

    expect(GitData).to receive(:create).with(@user.github_username, name, restricted: false, client: a_kind_of(Octokit::Client)) {
      obj = double(GitData)
      expect(obj).to receive(:add_file) { nil }
      expect(obj).to receive(:save) { nil }
      expect(obj).to receive(:html_url) { html_url }
      expect(obj).to receive(:name) { name.parameterize }
      expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
      obj
    }

    jekyll_service = JekyllService.new(dataset, nil)

    expect(dataset).to receive(:create_public_views)

    dataset.save
    dataset.reload

    expect(dataset.repo).to eq(name.parameterize)
    expect(dataset.url).to eq(html_url)
  end

  it "creates a repo with an organization" do
    name = "My Awesome Dataset"
    dataset = build(:dataset, :with_callback, user: @user, name: name, owner: "my-cool-organization")
    html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
    expect(GitData).to receive(:create).with('my-cool-organization', name, restricted: false, client: a_kind_of(Octokit::Client)) {
      obj = double(GitData)
      expect(obj).to receive(:html_url) { html_url }
      expect(obj).to receive(:name) { name.parameterize }
      expect(obj).to receive(:full_name) { "my-cool-organization/#{name.parameterize}" }
      obj
    }

    expect_any_instance_of(JekyllService).to receive(:add_files_to_repo_and_push_to_github)
    expect(dataset).to receive(:create_public_views)

    dataset.save
  end

  it "deletes a repo in github" do
    dataset = create(:dataset, user: @user, owner: "foo-bar")
    repo = dataset.instance_variable_get(:@repo)

    expect(repo).to receive(:delete)

    dataset.destroy
  end

  it "sets the user's avatar" do
    dataset = build(:dataset, :with_avatar_callback, user: @user)

    expect(@user).to receive(:avatar) {
      'http://example.com/avatar.png'
    }

    dataset.save

    expect(dataset.owner_avatar).to eq('http://example.com/avatar.png')
  end

  it "sets the owner's avatar" do
    dataset = build(:dataset, :with_avatar_callback, user: @user, owner: 'my-cool-organization')

    expect(Rails.configuration.octopub_admin).to receive(:organization).with('my-cool-organization') {
      double = double(Sawyer::Resource)
      expect(double).to receive(:avatar_url) {
        'http://example.com/my-cool-organization.png'
      }
      double
    }

    dataset.save

    expect(dataset.owner_avatar).to eq('http://example.com/my-cool-organization.png')
  end

  context('#fetch_repo') do

    before(:each) do
      @dataset = create(:dataset, user: @user, repo: "repo")
    end

    context('when repo exists') do

      before(:each) do
        @double = double(GitData)

        expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) {
          @double
        }
      end

      it "gets a repo from Github" do
        @dataset.fetch_repo
        expect(@dataset.instance_variable_get(:@repo)).to eq(@double)
      end

    end

    it 'returns nil if there is no schema present' do
      expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)).and_raise(Octokit::NotFound)

      @dataset.fetch_repo

      expect(@dataset.instance_variable_get(:@repo)).to be_nil
    end

  end

  it "generates a path" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect(dataset.path("filename")).to eq("filename")
    expect(dataset.path("filename", "folder")).to eq("folder/filename")
  end

  it "deletes a file in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")
    repo = dataset.instance_variable_get(:@repo)

    expect(repo).to receive(:delete_file).with("my-file")

    dataset.delete_file_from_repo("my-file")
  end

  it "generates the correct config" do
    dataset = build(:dataset, frequency: "weekly")
    config = YAML.load dataset.config

    expect(config["update_frequency"]).to eq("weekly")
  end

  context 'creating certificates for public datasets' do

    before(:each) do
      @dataset = create(:dataset)
      @certificate_url = 'http://staging.certificates.theodi.org/en/datasets/162441/certificate.json'
      allow(@dataset).to receive(:full_name) { "theodi/blockchain-and-distributed-technology-landscape-research" }
      allow(@dataset).to receive(:gh_pages_url) { "http://theodi.github.io/blockchain-and-distributed-technology-landscape-research" }
    end

    it "checks if page build is finished" do
      allow_any_instance_of(User).to receive(:octokit_client) do
        client = double(Octokit::Client)
        allow(client).to receive(:pages).with(@dataset.full_name) do
          OpenStruct.new(status: 'pending')
        end
        client
      end
      expect(@dataset.send(:gh_pages_built?)).to be false
    end

    it "confirms page build is finished" do
      allow_any_instance_of(User).to receive(:octokit_client) do
        client = double(Octokit::Client)
        allow(client).to receive(:pages).with(@dataset.full_name) do
          OpenStruct.new(status: 'built')
        end
        client
      end
      expect(@dataset.send(:gh_pages_built?)).to be true
    end


    it 'waits for the page build to finish then creates certificate' do
      expect(@dataset).to receive(:gh_pages_built?).and_return(false).once
      expect_any_instance_of(Object).to receive(:sleep).with(5)
      expect(@dataset).to receive(:gh_pages_built?).and_return(true).once
      expect(@dataset).to receive(:create_certificate).once

      @dataset.send :create_public_views
    end

    it 'creates a certificate' do
      factory = double(CertificateFactory::Certificate)

      expect(CertificateFactory::Certificate).to receive(:new).with(@dataset.gh_pages_url) {
        factory
      }

      expect(factory).to receive(:generate) {{ success: 'pending' }}
      expect(factory).to receive(:result) {{ certificate_url: @certificate_url }}
      expect(@dataset).to receive(:add_certificate_url).with(@certificate_url)

      @dataset.send(:create_certificate)
    end

    it 'adds the badge url to the repo' do
      expect(@dataset).to receive(:fetch_repo)
      expect_any_instance_of(JekyllService).to receive(:update_file_in_repo).with('_config.yml', {
        "data_source" => ".",
        "update_frequency" => "One-off",
        "certificate_url" => "http://staging.certificates.theodi.org/en/datasets/162441/certificate/badge.js"
      }.to_yaml)
      expect_any_instance_of(JekyllService).to receive(:push_to_github)

      @dataset.send(:add_certificate_url, @certificate_url)

      expect(@dataset.certificate_url).to eq('http://staging.certificates.theodi.org/en/datasets/162441/certificate')
    end

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
                       restricted: true)

      expect(dataset).to be_valid
      expect(dataset.restricted).to be true
    end

    it "creates a private repo in Github" do
      name = "My Awesome Dataset"
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"

      dataset = build(:dataset, :with_callback, user: @user, name: name, restricted: true)

      expect(GitData).to receive(:create).with(@user.github_username, name, restricted: true, client: a_kind_of(Octokit::Client)) {
        obj = double(GitData)
        expect(obj).to receive(:html_url) { html_url }
        expect(obj).to receive(:name) { name.parameterize }
        expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
        obj
      }

      expect_any_instance_of(JekyllService).to receive(:add_files_to_repo_and_push_to_github)
      expect(dataset).not_to receive(:create_public_views)

      dataset.save
      dataset.reload

      expect(dataset.repo).to eq(name.parameterize)
      expect(dataset.url).to eq(html_url)
    end


    it "can make a private repo public" do
      # Create dataset
      name = "My Awesome Dataset"
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
      dataset = build(:dataset, :with_callback, user: @user, name: name, restricted: true)
      expect(GitData).to receive(:create).with(@user.github_username, name, restricted: true, client: a_kind_of(Octokit::Client)) {
        obj = double(GitData)
        expect(obj).to receive(:add_file).once { nil }
        expect(obj).to receive(:save) { nil }
        expect(obj).to receive(:html_url) { html_url }
        expect(obj).to receive(:name) { name.parameterize }
        expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }

        obj
      }

      expect(dataset).to_not receive(:create_public_views)
      dataset.save

      # Update dataset and make public
      updated_dataset = Dataset.find(dataset.id)
      expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github).once

      expect(updated_dataset).to receive(:create_public_views).once
      updated_dataset.restricted = false
      repo = double(GitData)

      expect(repo).to receive(:make_public).once
      updated_dataset.instance_variable_set(:@repo, repo)
      updated_dataset.save
    end
  end

  context "notifying via twitter" do

    before(:all) do
      @tweeter = create(:user, name: "user-mcuser", email: "user@user.com", twitter_handle: "bob")
      @nontweeter = create(:user, name: "user-mcuser", email: "user@user.com", twitter_handle: nil)
    end

    before(:each) do
      allow_any_instance_of(Octokit::Client).to receive(:repository?) { false }
    end

    context "with twitter creds" do

      before(:all) do
        ENV["TWITTER_CONSUMER_KEY"] = "test"
        ENV["TWITTER_CONSUMER_SECRET"] = "test"
        ENV["TWITTER_TOKEN"] = "test"
        ENV["TWITTER_SECRET"] = "test"
      end

      it "sends twitter notification to twitter users" do
        expect_any_instance_of(Twitter::REST::Client).to receive(:update).with("@bob your dataset \"My Awesome Dataset\" is now published at http://user-mcuser.github.io/").once
        dataset = create(:dataset, name: "My Awesome Dataset",
                         description: "An awesome dataset",
                         publisher_name: "Awesome Inc",
                         publisher_url: "http://awesome.com",
                         license: "OGL-UK-3.0",
                         frequency: "One-off",
                         user: @tweeter)
      end

      it "doesn't send twitter notification to non twitter users" do
        expect_any_instance_of(Twitter::REST::Client).to_not receive(:update)
        dataset = create(:dataset, name: "My Awesome Dataset",
                         description: "An awesome dataset",
                         publisher_name: "Awesome Inc",
                         publisher_url: "http://awesome.com",
                         license: "OGL-UK-3.0",
                         frequency: "One-off",
                         user: @nontweeter)
      end
    end

    context "without twitter creds" do

      before(:all) do
        ENV.delete("TWITTER_CONSUMER_KEY")
        ENV.delete("TWITTER_CONSUMER_SECRET")
        ENV.delete("TWITTER_TOKEN")
        ENV.delete("TWITTER_SECRET")
      end

      it "doesn't send twitter notification" do
        expect_any_instance_of(Twitter::REST::Client).to_not receive(:update)
        dataset = create(:dataset, name: "My Awesome Dataset",
                         description: "An awesome dataset",
                         publisher_name: "Awesome Inc",
                         publisher_url: "http://awesome.com",
                         license: "OGL-UK-3.0",
                         frequency: "One-off",
                         user: @tweeter)
      end
    end
  end

end

