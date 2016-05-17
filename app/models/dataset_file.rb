class DatasetFile < ActiveRecord::Base

  belongs_to :dataset
  validate :check_schema

  attr_accessor :file

  def self.new_file(file)
    new(
      title: file["title"],
      filename: file["file"].original_filename,
      description: file["description"],
      mediatype: get_content_type(file["file"].original_filename),
    )
  end

  def self.update_file(file)
    f = find(file.delete("id"))
    f.update_file(file) unless f.nil?
    f
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
    original_file = self.dup

    update_hash = {
      title: file["title"],
      filename: file["file"].nil? ? nil : file["file"].original_filename,
      description: file["description"],
      mediatype: file["file"].nil? ? nil : self.class.get_content_type(file["file"].original_filename)
    }.delete_if { |k,v| v.nil? }

    self.update(update_hash)

    if file["file"]
      update_in_github(file["file"])
      delete_from_github(original_file) unless file["file"].original_filename == original_file.filename
    end
  end

  def add_to_github
    dataset.create_contents("data/#{filename}", file.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
    dataset.create_contents("data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
  end

  def update_in_github(tempfile)
    dataset.update_contents("data/#{filename}", tempfile.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
    dataset.update_contents("data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
    save
  end

  def delete_from_github(file)
    dataset.delete_contents(file.filename)
    dataset.delete_contents("#{File.basename(file.filename, '.*')}.md")
  end

  private

    def check_schema
      if dataset && dataset.schema
        schema = Csvlint::Schema.load_from_json(dataset.schema.tempfile)
        validation = Csvlint::Validator.new File.new(file.tempfile), {}, schema
        errors.add(:file, 'does not match schema') unless validation.valid?
      end
    end

end
