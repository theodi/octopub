require 'git_data'

class Dataset < ActiveRecord::Base

  belongs_to :user
  has_many :dataset_files

  before_create :create_in_github

  attr_accessor :schema
  
  validate :check_schema
  validates_associated :dataset_files

  def add_files(files_array)
    files_array.each do |file|
      dataset_files << DatasetFile.new_file(file, self)
    end
    save
    create_files
    push_to_github
  end

  def check_schema
    return nil unless schema
    s = Csvlint::Schema.load_from_json schema.tempfile, false
    unless s.fields.first
      errors.add :schema, 'is invalid'
    end
  end

  def update_files(files_array)
    fetch_repo
    files_array.each do |file|
      if file["id"]
        DatasetFile.update_file(file)
      else
        dataset_files << DatasetFile.new_file(file, self)
      end
    end
    update_datapackage
    push_to_github
  end

  def create_contents(filename, file)
    @repo.add_file(filename, file)
  end

  def update_contents(filename, file)
    @repo.update_file(filename, file)
  end

  def delete_contents(filename)
    @repo.delete_file(filename)
  end

  def path(filename, folder = "")
    File.join([folder,filename].reject { |n| n.blank? })
  end

  def create_files
    create_datapackage
    create_contents("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
    create_contents("_config.yml", config)
    create_contents("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
    create_contents("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
    create_contents("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
    create_contents("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
  end

  def create_datapackage
    create_contents("datapackage.json", datapackage)
  end

  def update_datapackage
    update_contents("datapackage.json", datapackage)
  end

  def datapackage
    datapackage = {}

    datapackage["name"] = name.downcase.parameterize
    datapackage["datapackage-version"] = ""
    datapackage["title"] = name
    datapackage["description"] = description
    datapackage["licenses"] = [{
      "url"   => license_details.url,
      "title" => license_details.title
    }]
    datapackage["publishers"] = [{
      "name"   => publisher_name,
      "web" => publisher_url
    }]

    datapackage["resources"] = []

    dataset_files.each do |file|
      datapackage["resources"] << {
        "url" => file.gh_pages_url,
        "name" => file.title,
        "mediatype" => file.mediatype,
        "description" => file.description,
        "path" => "data/#{file.filename}",
        "schema" => (JSON.parse(File.read(schema.tempfile)) unless schema.nil?)
      }.delete_if { |k,v| v.nil? }
    end

    datapackage.to_json
  end

  def config
    {
      "data_source" => ".",
      "update_frequency" => frequency,
    }.to_yaml
  end

  def license_details
    Odlifier::License.define(license)
  end

  def github_url
    "http://github.com/#{full_name}"
  end

  def gh_pages_url
    "http://#{user.github_username}.github.io/#{repo}"
  end

  def full_name
    "#{user.github_username}/#{repo}"
  end

  private

    def create_in_github
      @repo = GitData.create(user.name, name, client: user.octokit_client)
      self.url = @repo.html_url
      self.repo = @repo.name
    end

    def push_to_github
      @repo.save
    end

    def fetch_repo
      @repo = GitData.find(user.name, self.name, client: user.octokit_client)
    end

end
