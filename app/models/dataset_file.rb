# == Schema Information
#
# Table name: dataset_files
#
#  id                     :integer          not null, primary key
#  title                  :string
#  filename               :string
#  mediatype              :string
#  dataset_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  description            :text
#  file_sha               :text
#  view_sha               :text
#  dataset_file_schema_id :integer
#

class DatasetFile < ApplicationRecord

  belongs_to :dataset
  belongs_to :dataset_file_schema

  validate :check_schema, :check_csv
  validates_presence_of :title

  after_validation :set_filename

  attr_accessor :file

  def self.file_from_url(file)
    tempfile = Tempfile.new 'uploaded'
    tempfile.write read_file_with_utf_8(file)
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new filename: File.basename(file),
                                           content_type: 'text/csv',
                                           tempfile: tempfile
  end

  def self.read_file_with_utf_8(file)
    open(URI.escape(file)).read.force_encoding("UTF-8")
  end

  def self.new_file(dataset_file_creation_hash)

    # allow use of hashes or strings for keys
    dataset_file_creation_hash = ActiveSupport::HashWithIndifferentAccess.new(dataset_file_creation_hash)
    dataset_file_creation_hash[:file] = file_from_url(dataset_file_creation_hash[:file]) if dataset_file_creation_hash[:file].class == String

    logger.info "Dataset file created using new file #{ dataset_file_creation_hash[:file]}"
    # Do the actual create here
    create(
      title: dataset_file_creation_hash[:title],
      description: dataset_file_creation_hash[:description],
      file: dataset_file_creation_hash[:file]
    )
  end

  def github_url
    "#{dataset.github_url}/data/#{filename}"
  end

  def gh_pages_url
    "#{dataset.gh_pages_url}/data/#{filename}"
  end

  def update_file(file)
    file['file'] = DatasetFile.file_from_url(file['file']) if file["file"].class == String
    update_hash = {
      description: file["description"],
      file: file["file"],
      dataset_file_schema_id: file["dataset_file_schema_id"]
    }.delete_if { |k,v| v.nil? }

    self.update(update_hash)
  end

  def add_file_to_repo(repo, filename, file)
    p filename
    p "WOOF"
    ap file
    js = JekyllService.new(dataset, repo)
    js.add_file_to_repo(filename, file)
  end

  def update_file_in_repo(repo, filename, file)
    p filename
    p "WOOF"
    ap file
    js = JekyllService.new(dataset, repo)
    js.add_file_to_repo(filename, file)
  end

  def add_to_github(repo)
    add_file_to_repo(repo, "data/#{filename}", file.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
  end

  def add_jekyll_to_github(repo)
    add_file_to_repo(repo, "data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
  end

  def update_in_github(repo)
    update_file_in_repo(repo, "data/#{filename}", file.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
  end

  def update_jekyll_in_github(repo)
    update_file_in_repo(repo, "data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
  end

  def delete_from_github(file)
    dataset.delete_file_from_repo(file.filename)
    dataset.delete_file_from_repo("#{File.basename(file.filename, '.*')}.md")
  end

  private

    def check_schema
      logger.info "IN CHECK SCHEMA"
      if dataset_file_schema

        if dataset_file_schema.is_schema_valid?

          # TODO this could use the cached schema in the object, but for now...
          schema = Csvlint::Schema.load_from_json(URI.escape dataset_file_schema.url)

          # logger.info "Dataset file schema.url:"
          # logger.ap dataset_file_schema.url
          # logger.info "Dataset file schema.url - JSON parsed"
          # logger.ap JSON.generate(JSON.load(open(dataset_file_schema.url).read.force_encoding("UTF-8")))
          # logger.info "Loaded, linted schema object"
          # logger.ap schema
          # logger.ap the_data_file.read
          # logger.ap file.tempfile.path

          # TODO what does this do?
          schema.tables["file:#{get_file_for_validation_from_file.path}"] = schema.tables.delete schema.tables.keys.first if schema.respond_to? :tables

          validation = Csvlint::Validator.new(get_file_for_validation_from_file, {}, schema)

          # logger.ap schema.uri
          # logger.ap schema
          # logger.ap validation.valid?
          # #validation.validate
          # logger.ap validation.info_messages
          # logger.ap errors

          errors.add(:file, 'does not match the schema you provided') unless validation.valid?
          #logger.ap errors
        else
          errors.add(:schema, 'is not valid')
        end
      end
    end

    def get_file_for_validation_from_file
      File.new(file.tempfile)
    end

    def for_each_file_in_schema schema, &block
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

    def create_json_api_files schema
      for_each_file_in_schema(schema) do |filename, content|
        # Store data as JSON in file
        dataset.add_file_to_repo(filename, content.to_json)
      end
    end

    def create_json_jekyll_files schema
      for_each_file_in_schema(schema) do |filename, content|
        # Add human readable template
        unless filename == "index.json"
          if filename.scan('/').count > 0
            dataset.add_file_to_repo(filename.gsub('json', 'md'), File.open(File.join(Rails.root, "extra", "html", "api-item.md")).read)
          else
            dataset.add_file_to_repo(filename.gsub('json', 'md'), File.open(File.join(Rails.root, "extra", "html", "api-list.md")).read)
          end
        end
      end
    end

    def check_csv
      if dataset && file
        begin
          CSV.parse(file.tempfile.read.encode("UTF-8", invalid: :replace))
        rescue CSV::MalformedCSVError
          errors.add(:file, 'does not appear to be a valid CSV. Please check your file and try again.')
        rescue
          errors.add(:file, 'had some problems trying to upload. Please check your file and try again.')
        ensure
          file.tempfile.rewind
        end
      end
    end

    def set_filename
      self.filename = "#{title.parameterize}.csv" rescue nil
    end

end
