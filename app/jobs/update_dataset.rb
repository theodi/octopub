class UpdateDataset
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(id, user_id, dataset_params, files, options = {})
    files = [files] if files.class == Hash

    @user = User.find(user_id)
    dataset_params = ActiveSupport::HashWithIndifferentAccess.new(
      dataset_params.merge(job_id: self.jid)
    )

    @dataset = get_dataset(id, @user)
    @dataset.assign_attributes(dataset_params) if dataset_params

    handle_files(files)

    @dataset.report_status(options["channel_id"], :update)
  end

  def get_dataset(id, user)
    dataset = Dataset.find(id)
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
  end

  def update_file(id, file)
    f = @dataset.dataset_files.find { |this_file| this_file.id == id.to_i }

    if file["schema"]
      # Create schema
      # TODO if schema is existing, use it rather than create a new one
      schema = DatasetFileSchemaService.new(file["schema_name"], file["schema_description"], file["schema"], @user).create_dataset_file_schema
      file["dataset_file_schema_id"] = schema.id
    end

    f.update_file(file)
  end

  def add_file(jekyll_service, file)
    f = DatasetFile.new_file(file)
    if file["schema"]
      # Create schema
      # TODO if schema is existing, use it rather than create a new one
      schema = DatasetFileSchemaService.new(file["schema_name"], file["schema_description"], file["schema"], @user).create_dataset_file_schema
      f.dataset_file_schema_id = schema.id
    end

    @dataset.dataset_files << f
    if f.save
      jekyll_service.add_to_github(f) unless @dataset.local_private?
      jekyll_service.add_jekyll_to_github(f.filename) unless @dataset.local_private?
      f.file = nil
    end
  end
end
