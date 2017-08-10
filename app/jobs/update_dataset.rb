class UpdateDataset
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(id, user_id, dataset_params, files, options = {})
    files = [files] if files.class == Hash

    @user = User.find(user_id)
    dataset_params = ActiveSupport::HashWithIndifferentAccess.new(
      dataset_params.merge(job_id: self.jid)
    )

    @dataset = get_dataset(id)
    @dataset.assign_attributes(dataset_params) if dataset_params

    handle_files(files)

    @dataset.report_status(options["channel_id"], :update)
  end

  def get_dataset(dataset_id)
    dataset = Dataset.find(dataset_id)
    @repo = RepoService.fetch_repo(dataset) unless dataset.local_private?
    dataset
  end

  def handle_files(files)
    jekyll_service = JekyllService.new(@dataset, @repo)

    files.each do |file|

      if file["id"]
        update_file(file["id"], file)
      else
        add_file(jekyll_service, file)
      end
    end
    jekyll_service.push_to_github unless @dataset.local_private?
  end

  def update_file(id, update_file_hash)
    f = @dataset.dataset_files.find { |this_file| this_file.id == id.to_i }
    f.update_file(update_file_hash)
  end

  def add_file(jekyll_service, new_file_hash)
    f = DatasetFile.new_file(new_file_hash)

    @dataset.dataset_files << f
    if f.save
      jekyll_service.add_to_github(f) unless @dataset.local_private?
      jekyll_service.add_jekyll_to_github(f.filename) unless @dataset.local_private?
      f.file = nil
    end
  end
end
