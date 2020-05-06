class UpdateDatasetInGithub
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(dataset_id)
    dataset = Dataset.find(dataset_id)
    jekyll_service = JekyllService.new(dataset, RepoService.fetch_repo(dataset))
    jekyll_service.update_dataset_in_github
  end
end