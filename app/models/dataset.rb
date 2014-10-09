class Dataset < ActiveRecord::Base

  belongs_to :user
  has_many :dataset_files

  before_create :create_in_github

  def add_files(files_array)
    files_array.each do |file|
      dataset_files.new(
        title: file["title"],
        filename: file["file"].original_filename,
        tempfile: file["file"].tempfile
      )
    end
    save
    add_datapackage
  end

  def create_contents(filename, file, folder = "")
    path = folder.blank? ? filename : folder + "/" + filename
    user.octokit_client.create_contents(repo, path, "Adding #{filename}", file, branch: "gh-pages")
  end

  def add_datapackage
    create_contents("datapackage.json", datapackage)
  end

  def add_webpage
    create_contents("index.html", webpage)
  end

  def datapackage
    datapackage = {}

    datapackage["name"] = name
    datapackage["datapackage-version"] = ""
    datapackage["title"] = name
    datapackage["description"] = description
    datapackage["licenses"] = [{
      "url"   => license_details.url,
      "title" => license_details.title
    }]
    datapackage["publishers"] = [{
      "url"   => publisher_name,
      "title" => publisher_url
    }]

    datapackage["resources"] = []

    dataset_files.each do |file|
      datapackage["resources"] << {
        "url" => "http://github.com/#{repo}/data/#{file.filename}",
        "name" => file.filename,
        "mediatype" => "",
        "description" => file.title
      }
    end

    datapackage.to_json
  end

  def license_details
    Odlifier::License.define(license)
  end

  private

    def create_in_github
      repo = user.octokit_client.create_repository(name)
      self.url = repo[:html_url]
      self.repo = repo[:full_name]
    end

end
