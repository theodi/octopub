class DatasetFile < ActiveRecord::Base

  belongs_to :dataset

  validates :filename, format: { with: /.+\.csv/i, message: "We currently only support CSV files, please make sure this file is a CSV. If it is, please rename your file with the <code>.csv</code> extension" }

  attr_accessor :tempfile

  def initialize(file)
    params = {
      title: file["title"],
      filename: file["file"].original_filename,
      description: file["description"],
      mediatype: get_content_type(file["file"].original_filename),
      tempfile: file["file"].tempfile
    }
    super(params)
  end

  def get_content_type(file)
    type = MIME::Types.type_for(file).first
    (type.use_instead || [type.content_type]).first
  end

  def github_url
    "#{dataset.github_url}/data/#{filename}"
  end

  def gh_pages_url
    "#{dataset.gh_pages_url}/data/#{filename}"
  end

  def history_url
    "#{dataset.github_url}/commits/gh-pages/data/#{filename}"
  end

  def add_to_github
    dataset.create_contents(filename, tempfile.read, "data")
    dataset.create_contents("#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data")
  end

end
