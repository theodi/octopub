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
    name = dataset.name.parameterize
    html_url = "http://github.com/#{name}"

    expect(GitData).to receive(:new).with(a_kind_of(Octokit::Client), dataset.name, @user.name) {
      obj = double(GitData)
      expect(obj).to receive(:create)
      expect(obj).to receive(:html_url) { html_url }
      expect(obj).to receive(:name) { name }
      obj
    }

    dataset.save
    expect(dataset.repo).to eq(name)
    expect(dataset.url).to eq(html_url)
  end

  it "gets a repo from Github" do
    dataset = build(:dataset, user: @user, repo: "repo")
    dataset.save

    expect(GitData).to receive(:new).with(a_kind_of(Octokit::Client), dataset.name, @user.name) {
      obj = double(GitData)
      expect(obj).to receive(:find)
      obj
    }

    dataset = Dataset.last
    expect(dataset.instance_variable_get(:@repo)).to_not be_nil
  end

  it "generates a path" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect(dataset.path("filename")).to eq("filename")
    expect(dataset.path("filename", "folder")).to eq("folder/filename")
  end

  it "creates a file in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")
    repo = dataset.instance_variable_get(:@repo)

    expect(repo).to receive(:add_file).with("my-file", "File contents")

    dataset.create_contents("my-file", "File contents")
  end

  it "creates a file in a folder in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")
    repo = dataset.instance_variable_get(:@repo)

    expect(repo).to receive(:add_file).with("folder/my-file", "File contents")

    dataset.create_contents("folder/my-file", "File contents")
  end

  it "updates a file in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")
    repo = dataset.instance_variable_get(:@repo)

    expect(repo).to receive(:update_file).with("my-file", "File contents")

    dataset.update_contents("my-file", "File contents")
  end

  it "deletes a file in Github" do
    dataset = build(:dataset, user: @user, repo: "repo")

    expect_any_instance_of(Octokit::Client).to receive(:delete_contents).with(
      "#{@user.name}/repo",
      "my-file",
      "Deleting my-file",
      "abc1234",
      branch: "gh-pages"
    )

    dataset.delete_contents("my-file", "abc1234")
  end

  context "with files" do

    before(:each) do
      allow_any_instance_of(DatasetFile).to receive(:add_to_github) { nil }

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

      @dataset = build(:dataset, user: @user)
      @repo = @dataset.instance_variable_get(:@repo)

      allow(@dataset).to receive(:create_files) { nil }
      expect(@repo).to receive(:push)
    end

    it "adds a single file" do
      @dataset.add_files(@files)

      expect(@dataset.dataset_files.count).to eq(1)
      expect(@dataset.dataset_files.first.title).to eq(@name)
      expect(@dataset.dataset_files.first.filename).to eq(@file.original_filename)
      expect(@dataset.dataset_files.first.description).to eq(@description)
      expect(@dataset.dataset_files.first.mediatype).to eq("text/csv")
    end

    it "adds multiple files" do
      @files << {
        "title" => 'Test Data 2',
        "description" => Faker::Company.bs,
        "file" => @file
      }

      @dataset.add_files(@files)
      expect(@dataset.dataset_files.count).to eq(2)
    end
  end

  context "update_files" do

    before(:each) do
      @dataset = create(:dataset, user: @user)
      @file = create(:dataset_file, dataset: @dataset, filename: 'test-data.csv')
      @files = [{
        "id" => @file.id,
        "title" => "My super dataset",
        "description" => "Another super dataset"
      }]

      expect(@dataset).to receive(:update_datapackage)
    end

    it "updates the metadata of one file" do
      @dataset.update_files(@files)

      expect(@dataset.dataset_files.count).to eq(1)
      expect(@dataset.dataset_files.first.title).to eq("My super dataset")
      expect(@dataset.dataset_files.first.description).to eq("Another super dataset")
    end

    it "updates the metadata of multiple files" do
      file2 = create(:dataset_file, dataset: @dataset)

      @files << {
        "id" => file2.id,
        "title" => "My super dataset 2",
        "description" => "Another super dataset 2"
      }

      @dataset.update_files(@files)

      expect(@dataset.dataset_files.count).to eq(2)
      expect(@dataset.dataset_files.first.title).to eq("My super dataset")
      expect(@dataset.dataset_files.first.description).to eq("Another super dataset")
      expect(@dataset.dataset_files.last.title).to eq("My super dataset 2")
      expect(@dataset.dataset_files.last.description).to eq("Another super dataset 2")
    end

    it "updates a file in github" do
      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
      file = Rack::Test::UploadedFile.new(path, "text/csv")

      @files.first["file"] = file

      expect(DatasetFile).to receive(:find) { @file }
      expect(@file).to receive(:update_in_github).with(file)

      @dataset.update_files(@files)
    end

    it "adds new files" do
      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
      file = Rack::Test::UploadedFile.new(path, "text/csv")

      @files << {
        "title" => "New shiny",
        "description" => "Shiny new file",
        "file" => file
      }

      expect(DatasetFile).to receive(:new_file) { create(:dataset_file, dataset: @dataset) }

      @dataset.update_files(@files)

      expect(@dataset.dataset_files.count).to eq(2)
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
    expect(dataset).to receive(:create_contents).with("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
    expect(dataset).to receive(:create_contents).with("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
    expect(dataset).to receive(:create_contents).with("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
    expect(dataset).to receive(:create_contents).with("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)

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

  it "saves the datapackage", :vcr do
    dataset = create(:dataset, dataset_files: [
      create(:dataset_file)
    ])
    expect(dataset).to receive(:create_contents).with("datapackage.json", dataset.datapackage)
    dataset.create_datapackage
  end

  it "updates the datapackage" do
    dataset = create(:dataset)
    expect(dataset).to receive(:update_contents).with("datapackage.json", dataset.datapackage)
    dataset.update_datapackage
  end

  it "generates the correct config" do
    dataset = build(:dataset, frequency: "weekly")
    config = YAML.load dataset.config

    expect(config["update_frequency"]).to eq("weekly")
  end

end
