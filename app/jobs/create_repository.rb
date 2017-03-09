class CreateRepository
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(dataset_id)
    Rails.logger.info "in create_repo_and_populate"
    dataset = Dataset.find(dataset_id)
    @repo = RepoService.create_repo(dataset.repo_owner, dataset.name, dataset.restricted, dataset.user)

    CheckRepositoryIsCreated.perform_async(dataset_id)
  end
end
