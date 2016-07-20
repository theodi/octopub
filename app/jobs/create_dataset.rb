class CreateDataset
  include Sidekiq::Worker

  def perform(dataset_params, files, user_id, options = {})
    @user_id = user_id
    @dataset = dataset

    @dataset.assign_attributes(ActiveSupport::HashWithIndifferentAccess.new(
      dataset_params.merge(job_id: self.jid)
    ))

    files.each do |file|
      @dataset.dataset_files << DatasetFile.new_file(file)
    end

    @dataset.report_status(options[:channel_id])
  end

  def user
    User.find(@user_id)
  end

  def dataset
    user.datasets.new
  end

end
