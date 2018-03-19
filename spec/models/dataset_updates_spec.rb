require 'rails_helper'
require 'support/odlifier_licence_mock'

describe Dataset do
  include_context 'odlifier licence mock'

  before(:each) do
    @user = create(:user)
    Sidekiq::Testing.inline!
    allow(RepoService).to receive(:prepare_repo)
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  context "updating" do

    after(:each) do
      skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)
    end

    it "the public repo will be updated if the dataset is public" do
      mock_client = mock_pusher('beep-beep')
      mock_client = mock_pusher('beep-beep-boop')
      name = "this dataset"
      # Create dataset
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
      dataset = build(:dataset, :with_callback, user: @user, publishing_method: :github_public, name: name)

      obj = double(GitData)
      expect(GitData).to receive(:create).with(@user.github_username, name, restricted: false, client: a_kind_of(Octokit::Client)) {
        expect(obj).to receive(:add_file).once { nil }
        expect(obj).to receive(:save) { nil }
        expect(obj).to receive(:html_url) { html_url }
        expect(obj).to receive(:name) { name.parameterize }
        expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
        obj
      }
      allow(GitData).to receive(:find).with(@user.github_username, name, client: a_kind_of(Octokit::Client)) {
        obj
      }
      expect(RepoService).to receive(:prepare_repo)
      allow_any_instance_of(Dataset).to receive(:complete_publishing)

      dataset.report_status('beep-beep')

      # Update dataset and make public
      updated_dataset = Dataset.find(dataset.id)

      expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github).once
      expect(updated_dataset).to receive(:make_repo_public_if_appropriate).once
      expect(updated_dataset).to receive(:publish_public_views).once
      expect_any_instance_of(RepoService).to_not receive(:make_public)

      expect_any_instance_of(JekyllService).to_not receive(:create_public_views)

      updated_dataset.description = 'Woof woof'

      updated_dataset.report_status('beep-beep-boop', :update)
      expect(updated_dataset.description).to eq 'Woof woof'
    end

    it "the private github repo will be updated if the dataset is private github" do
      mock_client = mock_pusher('beep-beep')
      mock_client = mock_pusher('beep-beep-boop')
      name = "this dataset"
      # Create dataset
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
      dataset = build(:dataset, :with_callback, user: @user, publishing_method: :github_private, name: name)

      obj = double(GitData)
      expect(GitData).to receive(:create).with(@user.github_username, name, restricted: true, client: a_kind_of(Octokit::Client)) {
        expect(obj).to receive(:add_file).once { nil }
        expect(obj).to receive(:save) { nil }
        expect(obj).to receive(:html_url) { html_url }
        expect(obj).to receive(:name) { name.parameterize }
        expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
        obj
      }
      allow(GitData).to receive(:find).with(@user.github_username, name, client: a_kind_of(Octokit::Client)) {
        obj
      }

      allow_any_instance_of(Dataset).to receive(:complete_publishing)

      dataset.report_status('beep-beep')

      # Update dataset and make public
      updated_dataset = Dataset.find(dataset.id)

      expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github).once
      expect(updated_dataset).to receive(:make_repo_public_if_appropriate).once
      expect(updated_dataset).to receive(:publish_public_views).once
      expect_any_instance_of(RepoService).to_not receive(:make_public)
      expect_any_instance_of(JekyllService).to_not receive(:create_public_views)

      updated_dataset.description = 'Woof woof'

      updated_dataset.report_status('beep-beep-boop', :update)
      expect(updated_dataset.description).to eq 'Woof woof'
    end

    it "the private local repo will be updated if the dataset is private local, but no github action" do
      mock_client = mock_pusher('beep-beep')
      mock_client = mock_pusher('beep-beep-boop')
      name = "this dataset"
      # Create dataset
      html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
      dataset = build(:dataset, :with_callback, user: @user, publishing_method: :local_private, name: name)

      expect(GitData).to_not receive(:create)
      expect(GitData).to_not receive(:find)
      # expect(dataset).to receive(:send_success_email)

      expect_any_instance_of(Dataset).to_not receive(:complete_publishing)

      dataset.report_status('beep-beep')

      # Update dataset and make public
      updated_dataset = Dataset.find(dataset.id)

      expect_any_instance_of(JekyllService).to_not receive(:update_dataset_in_github)
      expect(updated_dataset).to_not receive(:make_repo_public_if_appropriate)
      expect(updated_dataset).to_not receive(:publish_public_views)

      expect_any_instance_of(RepoService).to_not receive(:make_public)
      expect_any_instance_of(JekyllService).to_not receive(:create_public_views)
      # expect(updated_dataset).to receive(:send_success_email)

      updated_dataset.description = 'Woof woof'
      updated_dataset.report_status('beep-beep-boop', :update)
      expect(updated_dataset.description).to eq 'Woof woof'
    end
  end
end
