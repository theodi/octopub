require 'spec_helper'

describe Dataset do

  before(:each) do
    @user = create(:user, name: "user-mcuser", email: "user@user.com")
  end

  it "creates a valid dataset" do
    dataset = create(:dataset, name: "My Awesome Dataset",
                     description: "An awesome dataset",
                     publisher_name: "Awesome Inc",
                     publisher_url: "http://awesome.com",
                     license: "OGL-UK-3.0",
                     frequency: "One-off",
                     user: @user)

    expect(dataset).to be_valid
  end

  it "creates a repo in Github" do
    dataset = build(:dataset, :with_callback, user: @user)
    name = "#{@user.name.downcase}/#{dataset.name.downcase}"
    html_url = "http://github.com/#{name}"

    expect_any_instance_of(Octokit::Client).to receive(:create_repository).with(dataset.name.downcase) {
        {
          name: name,
          html_url: html_url,
        }
    }

    dataset.save
    expect(dataset.repo).to eq(name)
    expect(dataset.url).to eq(html_url)
  end

  it "generates a path" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect(dataset.path("filename")).to eq("filename")
    expect(dataset.path("filename", "folder")).to eq("folder/filename")
  end

  it "creates a file in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
      "#{@user.name}/repo",
      "my-file",
      "Adding my-file",
      "File contents",
      branch: "gh-pages"
    )

    dataset.create_contents("my-file", "File contents")
  end

  it "creates a file in a folder in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
      "#{@user.name}/repo",
      "folder/my-file",
      "Adding my-file",
      "File contents",
      branch: "gh-pages"
    )

    dataset.create_contents("my-file", "File contents", "folder")
  end

  it "updates a file in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect_any_instance_of(Octokit::Client).to receive(:update_contents).with(
      "#{@user.name}/repo",
      "my-file",
      "Updating my-file",
      "abc1234",
      "File contents",
      branch: "gh-pages"
    )

    dataset.update_contents("my-file", "File contents", "abc1234")
  end


  context "with files" do

    before(:each) do
      filename = 'test-data.csv'
      path = File.join(Rails.root, 'spec', 'fixtures', filename)

      @name = 'Test Data'
      @description = Faker::Company.bs
      @file = Rack::Test::UploadedFile.new(path, "text/csv")

      @files = [
        {
          "title" => @name,
          "description" => @description,
          "file" => @file
        }
      ]
    end

    it "adds a single file" do
      dataset = build(:dataset, user: @user)
      allow(dataset).to receive(:create_files) { nil }

      dataset.add_files(@files)

      expect(dataset.dataset_files.count).to eq(1)
      expect(dataset.dataset_files.first.title).to eq(@name)
      expect(dataset.dataset_files.first.filename).to eq(@file.original_filename)
      expect(dataset.dataset_files.first.description).to eq(@description)
      expect(dataset.dataset_files.first.mediatype).to eq("text/csv")
    end

    it "adds multiple files" do
      dataset = build(:dataset, user: @user)
      allow(dataset).to receive(:create_files) { nil }

      @files << {
        "title" => 'Test Data 2',
        "description" => Faker::Company.bs,
        "file" => @file
      }

      dataset.add_files(@files)
      expect(dataset.dataset_files.count).to eq(2)
    end
  end

  it "sends the correct files to Github" do
    dataset = build :dataset, user: @user,
                              dataset_files: [
                                create(:dataset_file)
                              ]

    expect(dataset).to receive(:create_contents).with("datapackage.json", dataset.datapackage) { { content: {} }}
    expect(dataset).to receive(:create_contents).with("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
    expect(dataset).to receive(:create_contents).with("_config.yml", dataset.config)
    expect(dataset).to receive(:create_contents).with("style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read, "css")
    expect(dataset).to receive(:create_contents).with("default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read, "_layouts")
    expect(dataset).to receive(:create_contents).with("resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read, "_layouts")
    expect(dataset).to receive(:create_contents).with("data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read, "_includes")

    dataset.create_files
  end

  it "generates the correct datapackage contents" do
    file = create(:dataset_file, filename: "example.csv",
                                 title: "My Awesome File",
                                 description: "My Awesome File Description")
    dataset = build(:dataset, name: "My Awesome Dataset",
                              description: "My Awesome Description",
                              user: @user,
                              license: "OGL-UK-3.0",
                              publisher_name: "Me",
                              publisher_url: "http://www.example.com",
                              repo: "repo",
                              dataset_files: [
                                file
                              ])

    datapackage = JSON.parse(dataset.datapackage)

    expect(datapackage["name"]).to eq("my-awesome-dataset")
    expect(datapackage["title"]).to eq("My Awesome Dataset")
    expect(datapackage["description"]).to eq("My Awesome Description")
    expect(datapackage["licenses"].first).to eq({
      "url"   => "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/",
      "title" => "Open Government Licence 3.0 (United Kingdom)"
    })
    expect(datapackage["publishers"].first).to eq({
      "name"   => "Me",
      "web" => "http://www.example.com"
    })
    expect(datapackage["resources"].first).to eq({
      "url" => "http://user-mcuser.github.io/repo/data/example.csv",
      "name" => "My Awesome File",
      "mediatype" => "text/csv",
      "description" => "My Awesome File Description",
      "path" => "data/example.csv"
    })
  end

  it "saves the datapackage sha", :vcr do
    dataset = create(:dataset, dataset_files: [
      create(:dataset_file)
    ])
    expect(dataset).to receive(:create_contents).with("datapackage.json", dataset.datapackage) {
      {
        content: {
          sha: "abc1234"
        }
      }
    }
    dataset.create_datapackage

    expect(dataset.datapackage_sha).to eq("abc1234")
  end

  it "updates the datapackage sha" do
    dataset = create(:dataset, datapackage_sha: "abc1234")
    expect(dataset).to receive(:update_contents).with("datapackage.json", dataset.datapackage, "abc1234") {
      {
        content: {
          sha: "4321cba"
        }
      }
    }
    dataset.update_datapackage

    expect(dataset.datapackage_sha).to eq("4321cba")
  end

  it "generates the correct config" do
    dataset = build(:dataset, frequency: "weekly")
    config = YAML.load dataset.config

    expect(config["update_frequency"]).to eq("weekly")
  end

end
