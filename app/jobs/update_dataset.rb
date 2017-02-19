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

    @dataset.report_status(options["channel_id"])
  end

  def get_dataset(id, user)
    dataset = Dataset.find(id)
    ap user
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

    if file["schema"]
      # Create schema
      # TODO if schema is existing, use it rather than create a new one
      schema = DatasetFileSchemaService.new.create_dataset_file_schema(file["schema_name"], file["schema_description"], file["schema"], @user)
      file["dataset_file_schema_id"] = schema.id
    end

    f.update_file(file)
  end

  def add_file(file)

    @repo = @dataset.fetch_repo

    f = DatasetFile.new_file(file)
    if file["schema"]
      # Create schema
      # TODO if schema is existing, use it rather than create a new one
      schema = DatasetFileSchemaService.new.create_dataset_file_schema(file["schema_name"], file["schema_description"], file["schema"], @user)
      f.dataset_file_schema_id = schema.id
    end

    jekyll_service = JekyllService.new(@dataset, @repo)

    @dataset.dataset_files << f
    if f.save
      jekyll_service.add_to_github(f.filename, f.file)
      jekyll_service.add_jekyll_to_github(f.filename)    
      # f.add_to_github(@repo)
      # f.add_jekyll_to_github(@repo)
      f.file = nil
    end
  end

end
