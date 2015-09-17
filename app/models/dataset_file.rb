class DatasetFile < ActiveRecord::Base

  belongs_to :dataset

  after_create :add_to_github

  attr_accessor :tempfile

  def self.update_file(id, new_file)
    file = find(id)
    file.update_file(new_file) unless file.nil?
    file
  end

  def github_url
    "#{dataset.github_url}/data/#{filename}"
  end

  def gh_pages_url
    "#{dataset.gh_pages_url}/data/#{filename}"
  end

  def update_file(file)
    self.update(
      title: file["title"],
      filename: file["file"].original_filename,
      description: file["description"],
      mediatype: get_content_type(file["file"].original_filename),
    )
    update_in_github(file["file"])
  end

  private

    def add_to_github
      response = dataset.create_contents(filename, tempfile.read, "data")
      self.file_sha = response[:content][:sha]
      response = dataset.create_contents("#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data")
      self.view_sha = response[:content][:sha]
      save
    end

    def update_in_github(tempfile)
      response = dataset.update_contents(filename, tempfile.read, "data", file_sha)
      self.file_sha = response[:content][:sha]
      response = dataset.update_contents("#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data", view_sha)
      self.view_sha = response[:content][:sha]
      save
    end

    def get_content_type(file)
      type = MIME::Types.type_for(file).first
      [(type.use_instead || type.content_type)].flatten.first
    end

end
