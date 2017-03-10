require 'rails_helper'

describe CheckRepositoryIsCreated do

  before(:each) do

    @worker = CheckRepositoryIsCreated.new
    @user = create(:user)
    name = "My Awesome Dataset"  
    full_name = "my-cool-organization/#{name.parameterize}"
    @dataset = create(:dataset, user: @user, name: name)

    @html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
    @obj = double(GitData)

    allow(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) {
      expect(@obj).to receive(:html_url) { @html_url }
      expect(@obj).to receive(:name) { name.parameterize }
      expect(@obj).to receive(:full_name) { full_name }
      @obj
    }
  end

  after(:each) do
    set_dataset_callbacks!
  end

  it 'and updates columns' do
    @worker.perform(@dataset.id)
    @dataset.reload
    expect(@dataset.url).to eq(@html_url)
  end

  # it 'calls the next thing in the queue' do
  #   Sidekiq::Testing.inline!
  #   @worker.perform(@dataset.id)
    
  #   allow_any_instance_of(CreateJekyllFilesAndPushToGithub).to receive(:perform).with(@dataset_id).and_return { nil }
  #   Sidekiq::Testing.fake!
  # end

end

  # def perform(dataset_id)
  #   Rails.logger.info "in CheckRepositoryIsCreated"
  #   dataset = Dataset.find(dataset_id)
  #   # Throws Octokit not found if not there!
  #   repo = GitData.find(dataset.repo_owner, dataset.name, client: dataset.user.octokit_client)

  #   Rails.logger.info "Repo is found in CheckRepositoryIsCreated"
  #   # Now do the adding to the repository
  #   # Update column so don't trigger callback
  #   dataset.update_columns(url: repo.html_url, repo: repo.name, full_name: repo.full_name)
  #   Rails.logger.info "Now updated dataset with github details - call commit!"

  #   CreateJekyllFilesAndPushToGithub.perform_async(dataset_id)
  # end
