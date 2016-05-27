require 'git_data'

class Dataset < ActiveRecord::Base

  belongs_to :user
  has_many :dataset_files

  after_create :create_in_github
  after_update :update_in_github
  after_destroy :delete_in_github

  attr_accessor :schema

  validate :check_schema
  validates_associated :dataset_files

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
    "http://#{repo_owner}.github.io/#{repo}"
  end

  def full_name
    "#{repo_owner}/#{repo}"
  end

  def repo_owner
    owner.presence || user.github_username
  end

  def owner_avatar
    if owner.blank?
      user.avatar
    else
      user.octokit_client.organization(owner).avatar_url
    end
  end

  def fetch_repo
    begin
      @repo = GitData.find(repo_owner, self.name, client: user.octokit_client)
      check_for_schema
    rescue Octokit::NotFound
      @repo = nil
    end
  end

  def check_for_schema
    datapackage = JSON.parse @repo.get_file('datapackage.json')
    schema_json = datapackage['resources'].first['schema']
    unless schema_json.nil?
      self.schema = OpenStruct.new
      tempfile = Tempfile.new('schema')
      tempfile.write(schema_json.to_json)
      tempfile.rewind
      schema.tempfile = tempfile
    end
  end

  private

    def create_in_github
      @repo = GitData.create(repo_owner, name, client: user.octokit_client)
      self.update_columns(url: @repo.html_url, repo: @repo.name)
      commit
    end

    def commit
      dataset_files.each { |d| d.add_to_github }
      create_files
      push_to_github
    end

    def update_in_github
      dataset_files.each { |d| d.update_in_github if d.file }
      update_datapackage
      push_to_github
    end

    def delete_in_github
      @repo.delete if @repo
    end

    def push_to_github
      @repo.save
    end

    def check_schema
      return nil unless schema
      s = Csvlint::Schema.load_from_json schema.tempfile, false
      unless s.fields.first
        errors.add :schema, 'is invalid'
      end
    end

end
