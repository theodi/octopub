class UpdateDataset
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(id, user_id, dataset_params, files, options = {})
    files = [files] if files.class == Hash

    user = User.find(user_id)
    dataset_params = ActiveSupport::HashWithIndifferentAccess.new(
      dataset_params.merge(job_id: self.jid)
    )

    @dataset = get_dataset(id, user)
    @dataset.assign_attributes(dataset_params) if dataset_params

    handle_files(files)

    @dataset.report_status(options["channel_id"])
  end

  def get_dataset(id, user)
    dataset = Dataset.find(id)
    dataset.fetch_repo(user.octokit_client)
    dataset
  end

  def handle_files(files)
    files.each do |file|
      if file["id"]
        update_file(file["id"], file)
      else
        add_file(file)
      end
    end
  end

  def update_file(id, file)
    f = @dataset.dataset_files.find { |f| f.id == id.to_i }
    f.update_file(file)
  end

  def add_file(file)
    f = DatasetFile.new_file(file)
    @dataset.dataset_files << f
    if f.save
      f.add_to_github
      f.file = nil
    end
  end

end
