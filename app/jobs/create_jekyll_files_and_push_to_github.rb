class CreateJekyllFilesAndPushToGithub
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(dataset_id)
    Rails.logger.info "in CreateJekyllFilesAndPushToGithub"
    dataset = Dataset.find(dataset_id)
    repo = RepoService.fetch_repo(dataset)

    jekyll_service = JekyllService.new(dataset, repo)
    jekyll_service.add_files_to_repo_and_push_to_github

    dataset.complete_publishing

  end
end
