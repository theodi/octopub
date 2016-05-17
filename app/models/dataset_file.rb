class DatasetFile < ActiveRecord::Base

  belongs_to :dataset

  def self.new_file(file, dataset = nil)
    f = new(
      dataset: dataset,
      title: file["title"],
      filename: file["file"].original_filename,
      description: file["description"],
      mediatype: get_content_type(file["file"].original_filename),
    )
    f.add_to_github(file["file"])
    f
  end

  def add_and_validate_file file, dataset
    validation = Csvlint::validator.new file, nil, dataset.schema
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

  def add_to_github(tempfile)
    dataset.create_contents("data/#{filename}", tempfile.read.encode('UTF-8', :invalid => :replace, :undef => :replace))
    dataset.create_contents("data/#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
    save
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

end
