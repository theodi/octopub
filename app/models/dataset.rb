class Dataset < ActiveRecord::Base

  belongs_to :user
  has_many :dataset_files

  before_create :create_in_github

  def add_files(files_array)
    files_array.each do |file|
      dataset_files.new(
        title: file["title"],
        filename: file["file"].original_filename,
        description: file["description"],
        mediatype: get_content_type(file["file"].original_filename),
        tempfile: file["file"].tempfile
      )
    end
    save
    create_files
  end

  def create_contents(filename, file, folder = "")
    path = folder.blank? ? filename : folder + "/" + filename
    user.octokit_client.create_contents(full_name, path, "Adding #{filename}", file, branch: "gh-pages")
  end

  def create_files
    create_contents("datapackage.json", datapackage)
    create_contents("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
    create_contents("_config.yml", config)
    create_contents("style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read, "css")
    create_contents("default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read, "_layouts")
    create_contents("resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read, "_layouts")
    create_contents("data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read, "_includes")
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
        "path" => "data/#{file.filename}"
      }
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

  def get_content_type(file)
    type = MIME::Types.type_for(file).first
    [(type.use_instead || type.content_type)].flatten.first
  end

  def github_url
    "http://github.com/#{full_name}"
  end

  def gh_pages_url
    "http://#{user.name}.github.io/#{repo}"
  end

  def full_name
    "#{user.name}/#{repo}"
  end

  private

    def create_in_github
      repo = user.octokit_client.create_repository(name.downcase)
      self.url = repo[:html_url]
      self.repo = repo[:name]
    end

    def add_collaborator
      user.octokit_client.add_collaborator(name, ENV['GITHUB_USER'])
    end

end
