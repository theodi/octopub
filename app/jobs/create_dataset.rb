class CreateDataset
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(dataset_params, files, user_id, options = {})
    files = [files] if files.class == Hash
  
    user = find_user(user_id)
    @dataset = new_dataset_for_user(user)
   
    @dataset.assign_attributes(ActiveSupport::HashWithIndifferentAccess.new(
      dataset_params.merge(job_id: self.jid)
    ))

    unless @dataset.schema.nil? 
      logger.debug("We have a schema url #{@dataset.schema}")
      dataset_schema = DatasetSchemaService.new.create_dataset_schema(@dataset.schema, user)    
      @dataset.dataset_schema = dataset_schema
    end

    files.each do |file|
      @dataset.dataset_files << DatasetFile.new_file(file)
    end

    @dataset.report_status(options["channel_id"])
  end

  def find_user(user_id)
    User.find(user_id)
  end

  def new_dataset_for_user(user)
    user.datasets.new
  end

  def create_dataset_schema_for_user(user, url_in_s3)
    user.dataset_schemas.create(url_in_s3: url_in_s3)
  end

end
