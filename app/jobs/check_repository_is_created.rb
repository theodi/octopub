class CheckRepositoryIsCreated
  include Sidekiq::Worker
  sidekiq_options retry: 5

  def perform(dataset_id)
    Rails.logger.info "in CheckRepositoryIsCreated"
    dataset = Dataset.find(dataset_id)
    # Throws Octokit not found if not there!
    repo = RepoService.fetch_repo(dataset)
    Rails.logger.info "Repository Created, so now prepare repo"
    RepoService.prepare_repo(dataset)

    # Now do the adding to the repository
    # Update column so don't trigger callback
    dataset.update_columns(url: repo.html_url, repo: repo.name, full_name: repo.full_name)
    Rails.logger.info "Now updated dataset with github details - call commit!"

    CreateJekyllFilesAndPushToGithub.perform_async(dataset_id)
  end
end
