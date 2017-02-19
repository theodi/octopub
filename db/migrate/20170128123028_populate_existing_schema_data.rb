class PopulateExistingSchemaData < ActiveRecord::Migration[5.0]
  def up

    skip_callback_if_exists( Dataset, :update, :after, :update_dataset_in_github)
    skip_callback_if_exists( Dataset, :update, :after, :update_in_github) 

    Dataset.all.each do |dataset|
      schema_url = get_schema_url(dataset)
      schema = get_schema_from_repo(schema_url)
      next if schema.nil?

      puts "we have schema for #{dataset.name} #{schema}"
      # We have a schema
      dataset_file_schema = DatasetFileSchema.create(user_id: dataset.user.id, schema: schema, url_in_repo: schema_url, name: "#{dataset.name} migrated schema")
      dataset_file_schema.update(url_in_repo: schema_url)
      dataset.dataset_files.each do |dataset_file|
        dataset_file.update_columns(dataset_file_schema_id: dataset_file_schema.id)
      end
    end
  end

  def down
  end


  def get_schema_from_repo(schema_url)
    begin
      JSON.generate(JSON.load(open(schema_url, allow_redirections: :safe))).strip
    rescue OpenURI::HTTPError
      nil
    end
  end

  def gh_pages_url(dataset)
    "http://#{dataset.user.name}.github.io/#{dataset.repo}"
  end

  def get_schema_url(dataset)
    "#{gh_pages_url(dataset)}/schema.json"
  end

end

