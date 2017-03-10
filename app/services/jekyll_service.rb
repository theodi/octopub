class JekyllService

  def initialize(dataset, repo = nil)
    @dataset = dataset
    @repo = repo
    @repo_service = RepoService.new(repo)
  end

  def add_files_to_repo_and_push_to_github
    Rails.logger.info "in add_files_to_repo_and_push_to_github"
    create_data_files
    push_to_github
  end

  def create_data_files
    Rails.logger.info "Create data files and add to github"
    @dataset.dataset_files.each { |dataset_file| add_to_github(dataset_file) }
    Rails.logger.info "Create datapackage and add to repo"
    create_json_datapackage_and_add_to_repo

    @dataset.dataset_files.each do |dataset_file|
      dataset_file.validate
      if dataset_file.dataset_file_schema
        add_file_to_repo("#{dataset_file.dataset_file_schema.name.downcase.parameterize}.schema.json", dataset_file.dataset_file_schema.schema)
        # For ref, does a send as it's a private method
        create_json_api_files(dataset_file.file, dataset_file.dataset_file_schema.parsed_schema)
      end
    end

  end

  def push_to_github
    Rails.logger.info "In push_to_github method #{@repo_service}" 
    @repo_service.save
  end

  def create_jekyll_files
    Rails.logger.info "In create_jekyll_files"
    @dataset.dataset_files.each { |d| add_jekyll_to_github(d.filename) }
    add_file_to_repo("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
    add_file_to_repo("_config.yml", @dataset.config)
    add_file_to_repo("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
    add_file_to_repo("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
    add_file_to_repo("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
    add_file_to_repo("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
    add_file_to_repo("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
    add_file_to_repo("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
    add_file_to_repo("js/papaparse.min.js", File.open(File.join(Rails.root, "extra", "js", "papaparse.min.js")).read)

    @dataset.dataset_files.each do |f|
      create_json_jekyll_files(f.file, f.dataset_file_schema.parsed_schema) unless f.dataset_file_schema.nil?
    end
  end

  def add_to_github(dataset_file)
    string_io = FileStorageService.get_string_io(dataset_file.storage_key)
    add_file_to_repo("data/#{dataset_file.filename}", string_io.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
  end

  def add_jekyll_to_github(filename)
    add_file_to_repo("data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
  end

  def update_in_github(filename, file)
    Rails.logger.info 'update_in_github'
    #TODO remove string hack
    if file.instance_of? StringIO
      file.rewind if file.eof?
    end
    update_file_in_repo("data/#{filename}", file.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
  end

  def update_jekyll_in_github(filename)
    update_file_in_repo("data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
  end

  def create_json_datapackage_and_add_to_repo
    add_file_to_repo("datapackage.json", create_json_datapackage)
  end

  def add_file_to_repo(filename, file)
    @repo_service.add_file(filename, file)
  end

  def update_file_in_repo(filename, file)
    @repo_service.update_file(filename, file)
  end


  def path(filename, folder = "")
    File.join([folder,filename].reject { |n| n.blank? })
  end

  def update_dataset_in_github
    # Update files
    Rails.logger.info 'update_dataset_in_github'
    @dataset.dataset_files.each do |d|
      if d.file
        update_in_github(d.filename, d.file)
        update_jekyll_in_github(d.filename) unless @dataset.restricted?
      end
    end
    update_datapackage
    push_to_github
  end

  def delete_dataset_in_github
    @repo.delete if @repo
  end

  def create_json_datapackage
    name = @dataset.name
    datapackage = {}

    datapackage["name"] = name.downcase.parameterize
    datapackage["title"] = name
    datapackage["description"] = @dataset.description
    datapackage["licenses"] = [{
      "url"   => license_details.url,
      "title" => license_details.title
    }]
    datapackage["publishers"] = [{
      "name"   => @dataset.publisher_name,
      "web" => @dataset.publisher_url
    }]

    datapackage["resources"] = []

    @dataset.dataset_files.each do |file|
      datapackage["resources"] << {
        "name" => file.title,
        "mediatype" => 'text/csv',
        "description" => file.description,
        "path" => "data/#{file.filename}",
        "schema" => json_schema_for_datapackage(file.dataset_file_schema)
      }.delete_if { |k,v| v.nil? }
    end

    datapackage.to_json
  end

  def update_datapackage
    update_file_in_repo("datapackage.json", create_json_datapackage)
  end

  def json_schema_for_datapackage(dataset_file_schema)
    return if dataset_file_schema.nil? || dataset_file_schema.is_schema_otw?
    schema_hash = JSON.parse(dataset_file_schema.schema)
    schema_hash["name"] = dataset_file_schema.name
    schema_hash["description"] = dataset_file_schema.description
    schema_hash
  end

  def license_details
    Odlifier::License.define(@dataset.license)
  end

  def for_each_file_in_schema(file, schema, &block)
    return unless schema.class == Csvlint::Csvw::TableGroup
    # Generate JSON outputs
    schema.tables["file:#{file.tempfile.path}"] = schema.tables.delete schema.tables.keys.first if schema.respond_to? :tables
    files = Csv2rest.generate schema, base_url: File.dirname(schema.tables.first[0])
    # Add individual files to dataset
    (files || []).each do |filename, content|
      # Strip leading slash and create filename with extension
      filename = filename[1..-1]
      filename = "index" if filename == ""
      filename += ".json"
      # Strip leading slashes from urls and add json
      ([content].flatten).each do |content_item|
        if content_item["url"]
          content_item["url"] = content_item["url"].gsub(/^\//,"")
          content_item["url"] += ".json"
        end
      end
      # call the block
      block.call(filename, content)
    end
  end

  def create_json_api_files(file, schema)
    for_each_file_in_schema(file, schema) do |filename, content|
      # Store data as JSON in file
      add_file_to_repo(filename, content.to_json)
    end
  end

  def create_json_jekyll_files(file, schema)
    Rails.logger.info "In create_jekyll_files"
    for_each_file_in_schema(file, schema) do |filename, content|
      # Add human readable template
      unless filename == "index.json"
        if filename.scan('/').count > 0
          add_file_to_repo(filename.gsub('json', 'md'), File.open(File.join(Rails.root, "extra", "html", "api-item.md")).read)
        else
          add_file_to_repo(filename.gsub('json', 'md'), File.open(File.join(Rails.root, "extra", "html", "api-list.md")).read)
        end
      end
    end
  end
end
