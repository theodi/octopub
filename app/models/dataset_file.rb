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
#  storage_key            :string
#  validation							:boolean
#

class DatasetFile < ApplicationRecord

	require 'csvlint'

  belongs_to :dataset
  belongs_to :dataset_file_schema

  validate :check_schema, if: :content_or_schema_changed?
  validate :check_csv, if: :content_or_schema_changed?
  validates_presence_of :title
  validates_presence_of :storage_key, on: :create

  after_validation :set_filename

  default_scope { order(:created_at) }

  attr_accessor :file

  def self.file_from_url(file)
    Rails.logger.info "DatasetFile: In file_from_url"
    tempfile = Tempfile.new 'uploaded'
    tempfile.write read_file_with_utf_8(file)
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new filename: File.basename(file),
                                           # content_type: 'text/csv',
                                           tempfile: tempfile
  end

  def self.file_from_url_with_storage_key(file, storage_key)
    Rails.logger.info "DatasetFile: In file_from_url_with_storage_key"

    fs_file = FileStorageService.get_string_io(storage_key)
    ActionDispatch::Http::UploadedFile.new filename: File.basename(file),
                                           # content_type: 'text/csv',
                                           tempfile: fs_file
  end

  def self.read_file_with_utf_8(file)
    open(URI.escape(file)).read.force_encoding("UTF-8")
  end

  def self.create(dataset_file_creation_hash)
    Rails.logger.info "DatasetFile: In create"
    # allow use of hashes or strings for keys
    dataset_file_creation_hash = get_file_from_the_right_place(dataset_file_creation_hash)
    Rails.logger.info "Dataset file created using new file #{dataset_file_creation_hash[:file]} key: #{dataset_file_creation_hash[:storage_key]}"
    # Do the actual create here
    super(
      title: dataset_file_creation_hash[:title],
      description: dataset_file_creation_hash[:description],
      file: dataset_file_creation_hash[:file],
      storage_key: dataset_file_creation_hash[:storage_key],
      dataset_file_schema_id: dataset_file_creation_hash[:dataset_file_schema_id]
    )
  end

  def self.get_file_from_the_right_place(dataset_file_hash)
    dataset_file_hash = ActiveSupport::HashWithIndifferentAccess.new(dataset_file_hash)
    if dataset_file_hash[:file].class == String
      if dataset_file_hash[:storage_key]
        # File already uploaded so fetch from S3
        dataset_file_hash[:file] = file_from_url_with_storage_key(dataset_file_hash[:file], dataset_file_hash[:storage_key])
      else
        dataset_file_hash[:file] = file_from_url(dataset_file_hash[:file])
      end
    end
    dataset_file_hash
  end

  def github_url
    "#{dataset.github_url}/data/#{filename}"
  end

  def gh_pages_url
    "#{dataset.gh_pages_url}/data/#{filename}"
  end

  def schema_name
    dataset_file_schema.name if dataset_file_schema
  end
	
  def update_file(file_update_hash)
    Rails.logger.info "DatasetFile: In update_file"
    file_update_hash = DatasetFile.get_file_from_the_right_place(file_update_hash)

    update_hash = {
      description: file_update_hash[:description],
      file: file_update_hash[:file],
      dataset_file_schema_id: file_update_hash[:dataset_file_schema_id],
      storage_key: file_update_hash[:storage_key]
    }.delete_if { |_k,v| v.nil? }

    self.update(update_hash)
  end

  private

    def content_or_schema_changed?
      # We only need to validate if the file itself or the schema has changed
      new_record? ||
      dataset_file_schema_id_changed? ||
      storage_key_changed?
    end

    def check_schema
      Rails.logger.info "DatasetFile: In check schema"
      if dataset_file_schema
        if dataset_file_schema.is_schema_valid?
          if dataset_file_schema.csv_on_the_web_schema
            validate_schema_cotw
          else
            validate_schema_non_cotw
          end
        else
          errors.add(:schema, 'is not valid')
        end
      end
    end

    def validate_schema_cotw
      Rails.logger.info "DatasetFile: we have COTW schema and schema is valid, so validate"

      schema = Csvlint::Schema.load_from_string(URI.escape(dataset_file_schema.url), dataset_file_schema.schema)
      tempfile = get_file_for_validation_from_file

      if schema.respond_to? :tables
        schema.tables["file:#{tempfile.path}"] = schema.tables.delete(schema.tables.keys.first)
      end
      validation = Csvlint::Validator.new(tempfile, {}, schema)

      errors.add(:file, 'does not match the schema you provided') unless validation.valid?
      Rails.logger.info "DatasetFile: check schema, number of errors #{errors.count}"
      errors
    end


    def validate_schema_non_cotw
      Rails.logger.info "DatasetFile: we have non COTW schema and schema is valid, so validate"

      schema = Csvlint::Schema.load_from_string(URI.escape(dataset_file_schema.url), dataset_file_schema.schema)

      validation = Csvlint::Validator.new(file_content, {}, schema)

      errors.add(:file, 'does not match the schema you provided') unless validation.valid?
      Rails.logger.info "DatasetFile: check schema, number of errors #{errors.count}"
      errors
    end

    def get_file_for_validation_from_file
      File.new(file.tempfile)
    end

    def check_csv
      if file_extension == '.csv'
        content = file_content
        unless content.nil?
          begin
            CSV.parse(content.read)
          rescue CSV::MalformedCSVError
            errors.add(:file, 'does not appear to be a valid CSV. Please check your file and try again.')
          rescue
            errors.add(:file, 'had some problems trying to upload. Please check your file and try again.')
          ensure
            file_content.rewind
          end
        end
      end
    end

    def file_extension
      file = self.storage_key || self.file.original_filename || ''
      File.extname(file)
    end

    def set_filename
      self.filename = "#{title.parameterize}" << file_extension rescue nil
    end

    def file_content
      # Try to load from the storage key first.
      if storage_key
        # This might fail if the S3 content has gone away.
        begin
          return FileStorageService.get_string_io(storage_key)
        rescue Aws::S3::Errors::NoSuchKey
          # OK, the S3 content disappeared. Carry on.
        end
      end
      # If that didn't help, we try to load from the pubished version on GitHub
      if dataset && dataset.github_public?
        begin
          return open(gh_pages_url)
        rescue OpenURI::HTTPError => ex
          # Absorb 404s, but throw anything else up the stack
          throw unless ex.message === "404 Not Found"
        end
      end
      # Nothing worked. Ah well. We did our best.
      nil
    end

end
