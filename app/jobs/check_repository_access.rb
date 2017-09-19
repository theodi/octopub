class CheckRepositoryAccess
  include Sidekiq::Worker
  sidekiq_options retry: 5

  def perform(dataset_id)
    Rails.logger.info "in CheckRepositoryAccess"
    dataset = Dataset.find(dataset_id)
  end
end
