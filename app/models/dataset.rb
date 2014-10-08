class Dataset < ActiveRecord::Base

  belongs_to :user
  before_create :create_in_github

  def add_files(files)
    files.each { |file| create_contents(file["file"].original_filename, file["file"].tempfile.read) }
    add_datapackage(files)
  end

  def create_contents(filename, file)
    user.octokit_client.create_contents(repo, filename, "Adding #{filename}", file)
  end

  def add_datapackage(files)
    create_contents("datapackage.json", datapackage(files))
  end

  def datapackage(files)
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

    files.each do |file|
      datapackage["resources"] << {
        "url" => "http://github.com/#{repo}/data/#{file["file"].original_filename}",
        "name" => "#{file["file"].original_filename}",
        "mediatype" => "",
        "description" => "#{file["title"]}"
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
