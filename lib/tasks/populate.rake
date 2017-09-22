namespace :populate do
  
  task :schemas => :environment do
    
    skip_callback_if_exists( Dataset, :update, :after, :update_dataset_in_github)
    skip_callback_if_exists( Dataset, :update, :after, :update_in_github) 

    Dataset.all.each do |dataset|
      puts "checking '#{dataset.name}'"
      if dataset.dataset_files.any? {|f| f.dataset_file_schema.nil? }

        puts " - some files don't have schemas"
        schema_url = get_schema_url(dataset)
        schema = get_schema_from_repo(schema_url)
        
        if schema.nil?
          puts(" - no schema found at #{schema_url}")
          next 
        end

        puts " - loaded schema from: #{schema_url}"
        # We have a schema
        dataset_file_schema = DatasetFileSchema.create(
          user_id: dataset.user.id, 
          owner_username: dataset.owner,
          schema: schema, 
          url_in_repo: schema_url,
          name: "#{dataset.name} migrated schema"
        )
        if dataset_file_schema.valid?
          puts " - schema created with ID #{dataset_file_schema.id}"
          dataset.dataset_files.each do |dataset_file|
            if dataset_file.dataset_file_schema_id.nil?
              puts " - assigning schema to file #{dataset_file.name}"
              dataset_file.update_columns(dataset_file_schema_id: dataset_file_schema.id) 
            else      
              puts " - skipping file #{dataset_file.name}"
            end
          end
        else
          puts " - schema created with ID #{dataset_file_schema.id}"
        end
      else
        puts " - already has schemas loaded"
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

  def get_schema_url(dataset)
    "#{dataset.gh_pages_url}/schema.json"
  end

end
