class CreateDataset
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(dataset_params, files, user_id, options = {})
    files = [files] if files.class == Hash
  
    user = find_user(user_id)
    @dataset = new_dataset_for_user(user)
    logger.info(dataset_params.inspect)

    if dataset_params.include?('schema') || dataset_params.include?(:schema)
      logger.info("We have a schema url")
      url_in_s3 = dataset_params[:schema]
      @dataset_schema = create_dataset_schema_for_user(user, url_in_s3)
      logger.ap @dataset_schema
    else
      logger.info("We do not have a schema url")
    end

    @dataset.assign_attributes(ActiveSupport::HashWithIndifferentAccess.new(
      dataset_params.merge(job_id: self.jid)
    ))

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
