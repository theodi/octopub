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

    files.each do |file|
      dataset_file = DatasetFile.new_file(file)
      if file["schema"]
        # Create schema
        # TODO if schema is existing, use it rather than create a new one
        schema = DatasetFileSchemaService.new.create_dataset_file_schema(file["schema_name"], file["schema_description"], file["schema"], user)
        dataset_file.dataset_file_schema = schema
      end
      @dataset.dataset_files << dataset_file
    end

    @dataset.report_status(options["channel_id"])
  end

  def find_user(user_id)
    User.find(user_id)
  end

  def new_dataset_for_user(user)
    user.datasets.new
  end

end

# Results from Files array - just what's required
# [
#     [0] {
#                                   "title" => "Fri1414",
#                             "description" => "Fri1414",
#                                    "file" => "https://jj-octopub-development.s3-eu-west-1.amazonaws.com/uploads/ef2d221a-3210-40c0-af49-0bfe39b139be/australian-open-data-publishers.csv",
#         "existing_dataset_file_schema_id" => "",
#                             "schema_name" => "Fri1414",
#                      "schema_description" => "Fri1414",
#                                  "schema" => "https://jj-octopub-development.s3-eu-west-1.amazonaws.com/uploads/ef2d221a-3210-40c0-af49-0bfe39b139be/schema.json"
#     }
# ]
