class PopulateExistingSchemaData < ActiveRecord::Migration[5.0]
  def up

    Dataset.skip_callback(:update, :after, :update_in_github)

    Dataset.all.each do |dataset|
      schema_url = get_schema_url(dataset)
      schema = get_schema_from_repo(schema_url)
      next if schema.nil?
      puts "we have schema for #{dataset.name} #{schema}"
      # We have a schema
     # dataset_schema = DatasetSchema.where(user_id: dataset.user.id, schema: schema).first_or_create
      dataset_schema = DatasetSchema.create(user_id: dataset.user.id, schema: schema, url_in_repo: schema_url)
      dataset_schema.update(url_in_repo: schema_url)
      dataset.update(dataset_schema_id: dataset_schema.id)
      ap dataset_schema
    end
  end

  def down
  end


  def get_schema_from_repo(schema_url)
    begin
      JSON.generate(JSON.load(open(schema_url, allow_redirections: :safe)))
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

