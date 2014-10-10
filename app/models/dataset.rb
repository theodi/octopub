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
    add_datapackage
    add_webpage
  end

  def create_contents(filename, file, folder = "")
    path = folder.blank? ? filename : folder + "/" + filename
    user.octokit_client.create_contents(full_name, path, "Adding #{filename}", file, branch: "gh-pages")
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
        "url" => file.gh_pages_url,
        "name" => file.title,
        "mediatype" => "",
        "description" => file.description
      }
    end

    datapackage.to_json
  end

  def webpage
    ac = ActionController::Base.new()
    ac.render_to_string(File.join(Rails.root, "app", "views", "datasets", "webpage.html.erb"), locals: { dataset: self }).to_s
  end

  def license_details
    Odlifier::License.define(license)
  end

  def get_content_type(file)
    type = MIME::Types.type_for(file).first
    (type.use_instead || [type.content_type]).first
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

  def issues_url
    "#{github_url}/issues"
  end

  def atom_url
    "#{github_url}/commits/gh_pages.atom"
  end

  private

    def create_in_github
      repo = user.octokit_client.create_repository(name)
      self.url = repo[:html_url]
      self.repo = repo[:name]
    end

end
