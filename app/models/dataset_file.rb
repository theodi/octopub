class DatasetFile < ActiveRecord::Base

  belongs_to :dataset

  validate :check_schema, :check_csv
  validates_presence_of :title

  after_validation :set_filename

  attr_accessor :file

  def self.file_from_url(file)
    tempfile = Tempfile.new 'uploaded'
    tempfile.write open("https:#{URI.escape(file)}").read.force_encoding("UTF-8")
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new filename: File.basename(file),
                                           content_type: 'text/csv',
                                           tempfile: tempfile
  end

  def self.new_file(file)
    file['file'] = file_from_url(file['file']) if file["file"].class == String

    create(
      title: file["title"],
      description: file["description"],
      mediatype: get_content_type(file["file"].original_filename),
      file: file["file"]
    )
  end

  def self.get_content_type(file)
  #  type = MIME::Types.type_for(file).first
  #  [(type.use_instead || type.content_type)].flatten.first

    return 'text/csv'
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
    }.delete_if { |k,v| v.nil? }

    self.update(update_hash)
  end

  def add_to_github
    dataset.create_contents("data/#{filename}", file.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
    dataset.create_contents("data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
  end

  def update_in_github
    dataset.update_contents("data/#{filename}", file.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
    dataset.update_contents("data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
  end

  def delete_from_github(file)
    dataset.delete_contents(file.filename)
    dataset.delete_contents("#{File.basename(file.filename, '.*')}.md")
  end

  private

    def check_schema
      if dataset && dataset.schema && file
        schema = Csvlint::Schema.load_from_json(dataset.schema.tempfile)

        schema.tables["file:#{file.tempfile.path}"] = schema.tables.delete schema.tables.keys.first if schema.respond_to? :tables

        validation = Csvlint::Validator.new File.new(file.tempfile), {}, schema
        errors.add(:file, 'does not match the schema you provided') unless validation.valid?

        create_json_api_files schema
      end
    end

    def create_json_api_files schema
      return unless schema.class == Csvlint::Csvw::TableGroup
      # Generate JSON outputs
      files = Csv2rest.generate schema, base_url: File.dirname(schema.tables.first[0].gsub("file:","")) rescue nil
      # Add individual files to dataset
      (files || []).each do |filename, content|
        # Strip leading slash and create filename with extension
        filename = filename[1..-1]
        filename = "index" if filename == ""
        filename += ".json"
        # Store data as JSON in file
        dataset.create_contents(filename, content.to_json)
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
