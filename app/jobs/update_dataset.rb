class UpdateDataset
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(id, dataset_params, files, options = {})
    files = [files] if files.class == Hash

    dataset_params = ActiveSupport::HashWithIndifferentAccess.new(
      dataset_params.merge(job_id: self.jid)
    )

    @dataset = get_dataset(id)

    user_id = dataset_params[:user_id].try(:to_i)
    # Give new user access to repo
    if @dataset.publishing_method != 'local_private' &&
        user_id &&
        user_id != @dataset.user_id
      new_user = User.find(user_id)
      dataset_params[:user] = new_user
      if new_user
        @dataset.user.octokit_client.add_collaborator(@dataset.full_name, new_user.github_username)
      end
    end

    # Update
    @dataset.assign_attributes(dataset_params) if dataset_params
    handle_files(files)

    @dataset.report_status(options["channel_id"], :update)

    if @dataset.published_status == 'published'
      @dataset.update_attribute(:published_status, 'revised')
    end
  end

  def get_dataset(dataset_id)
    dataset = Dataset.find(dataset_id)
    # @repo = RepoService.fetch_repo(dataset) unless dataset.local_private?
    dataset
  end

  def handle_files(files)
    # jekyll_service = JekyllService.new(@dataset, @repo)
    added = false
    files.each do |file|

      if file["id"]
        update_file(file["id"], file)
      else
        # add_file(jekyll_service, file)
        add_file(file)
        added = true
      end
    end
    # jekyll_service.push_to_github if added && !@dataset.local_private?
  end

  def update_file(id, update_file_hash)
    f = @dataset.dataset_files.find { |this_file| this_file.id == id.to_i }
    f.update_file(update_file_hash)
  end

  # def add_file(jekyll_service, new_file_hash)
  def add_file(new_file_hash)
    f = DatasetFile.create(new_file_hash)

    @dataset.dataset_files << f
    if f.save
      # jekyll_service.add_to_github(f) unless @dataset.local_private?
      # jekyll_service.add_jekyll_to_github(f.filename) unless @dataset.local_private?
      f.file = nil
    end
  end
end
