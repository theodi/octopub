class DatasetFile < ActiveRecord::Base

  belongs_to :dataset
  validate :check_schema, :check_csv

  attr_accessor :file

  def self.new_file(file)
    new(
      title: file["title"],
      filename: file["file"].original_filename,
      description: file["description"],
      mediatype: get_content_type(file["file"].original_filename),
      file: file["file"]
    )
  end

  def self.get_content_type(file)
    type = MIME::Types.type_for(file).first
    [(type.use_instead || type.content_type)].flatten.first
  end

  def github_url
    "#{dataset.github_url}/data/#{filename}"
  end

  def gh_pages_url
    "#{dataset.gh_pages_url}/data/#{filename}"
  end

  def update_file(file)
    update_hash = {
      title: file["title"],
      description: file["description"],
      mediatype: file["file"].nil? ? nil : self.class.get_content_type(file["file"].original_filename),
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
      end
    end

    def check_csv
      if dataset && file
        begin
          CSV.parse(file.tempfile.read)
        rescue CSV::MalformedCSVError
          errors.add(:file, 'does not appear to be a valid CSV. Please check your file and try again.')
        rescue
          errors.add(:file, 'had some problems trying to upload. Please check your file and try again.')
        ensure
          file.tempfile.rewind
        end
      end
    end

end
