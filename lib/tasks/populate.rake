namespace :populate do
  
  task :schemas => :environment do
    
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
        dataset_file.update_columns(dataset_file_schema: dataset_file_schema) if dataset_file.dataset_file_schema.nil?
      end
    end
    
  end
  
  # Utility methods
  
  def skip_callback_if_exists(thing, name, kind, filter)
    if any_callbacks?(thing._update_callbacks, name, kind, filter)
      thing.skip_callback(name, kind, filter)
    end
  end

  def any_callbacks?(callbacks, name, kind, filter)
    callbacks.select { |cb| cb.name == name && cb.kind == kind && cb.filter == filter }.any?
  end

  def get_schema_from_repo(schema_url)
    begin
      JSON.generate(JSON.load(open(schema_url, allow_redirections: :safe))).strip
    rescue OpenURI::HTTPError
      nil
    end
  end

  def gh_pages_url(dataset)
    name = dataset.owner || dataset.user.github_username
    "http://#{name}.github.io/#{dataset.repo}"
  end

  def get_schema_url(dataset)
    "#{gh_pages_url(dataset)}/schema.json"
  end

end