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
    name = "My Awesome Dataset"
    html_url = "http://github.com/#{@user.name}/#{name.parameterize}"

    dataset = build(:dataset, :with_callback, user: @user, name: name)

    expect(GitData).to receive(:create).with(@user.name, name, client: a_kind_of(Octokit::Client)) {
      obj = double(GitData)
      expect(obj).to receive(:html_url) { html_url }
      expect(obj).to receive(:name) { name.parameterize }
      obj
    }

    expect(dataset).to receive(:commit)

    dataset.save
    expect(dataset.repo).to eq(name.parameterize)
    expect(dataset.url).to eq(html_url)
  end

  context('#fetch_repo') do

    before(:each) do
      dataset = build(:dataset, user: @user, repo: "repo")
      dataset.save

      @double = double(GitData)

      expect(GitData).to receive(:find).with(@user.name, dataset.name, client: a_kind_of(Octokit::Client)) {
        @double
      }
    end

    it "gets a repo from Github" do
      dataset = Dataset.last

      expect(dataset).to receive(:check_for_schema)
      dataset.fetch_repo
      expect(dataset.instance_variable_get(:@repo)).to eq(@double)
    end

    it "gets a schema" do
      expect(@double).to receive(:get_file).with('datapackage.json') {
        File.read(File.join(Rails.root, 'spec', 'fixtures', 'datapackage.json'))
      }

      dataset = Dataset.last
      dataset.fetch_repo

      expect(File.read(dataset.schema.tempfile)).to eq({
        fields: [
          {
            name: "Username",
            constraints: {
              required: true,
              unique: true,
              minLength: 5,
              maxLength: 10,
              pattern: "^[A-Za-z0-9_]*$"
            }
          },
          {
            name: "Age",
            constraints: {
              type: "http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
              minimum: "13",
              maximum: "99"
            }
          },
          {
            name: "Height",
            constraints: {
              type: "http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
              minimum: "20"
            }
          },
          {
            name: "Weight",
            constraints: {
              type: "http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
              maximum: "500"
            }
          },
          {
            name: "Password"
          }
        ]
      }.to_json)
    end

    it 'returns nil if there is no schema present' do
      expect(@double).to receive(:get_file).with('datapackage.json') {
        File.read(File.join(Rails.root, 'spec', 'fixtures', 'datapackage-without-schema.json'))
      }

      dataset = Dataset.last
      dataset.fetch_repo

      expect(dataset.schema).to be_nil
    end

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
    repo = dataset.instance_variable_get(:@repo)

    expect(repo).to receive(:delete_file).with("my-file")

    dataset.delete_contents("my-file")
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

  context "schemata" do
    it 'is unhappy with a duff schema' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/bad-schema.json')
      schema = Rack::Test::UploadedFile.new(path, "text/csv")
      dataset = build(:dataset, schema: schema)

      expect(dataset.valid?).to be false
      expect(dataset.errors.messages[:schema].first).to eq 'is invalid'
    end

    it 'is happy with a good schema' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      schema = Rack::Test::UploadedFile.new(path, "text/csv")
      dataset = build(:dataset, schema: schema)

      expect(dataset.valid?).to be true
    end

    it 'adds the schema to the datapackage' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      schema = Rack::Test::UploadedFile.new(path, "text/csv")
      file = create(:dataset_file, filename: "example.csv",
                                   title: "My Awesome File",
                                   description: "My Awesome File Description")


      dataset = build(:dataset, schema: schema, dataset_files: [file])
      datapackage = JSON.parse dataset.datapackage

      expect(datapackage['resources'].first['schema']['fields']).to eq([
        {
          "name" => "Username",
          "constraints" => {
            "required"=>true,
            "unique"=>true,
            "minLength"=>5,
            "maxLength"=>10,
            "pattern"=>"^[A-Za-z0-9_]*$"
          }
        },
        {
          "name" => "Age",
          "constraints" => {
            "type"=>"http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
            "minimum"=>"13",
            "maximum"=>"99"
          }
        },
        {
           "name"=>"Height",
           "constraints" => {
             "type"=>"http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
             "minimum"=>"20"
           }
        },
        {
          "name"=>"Weight",
          "constraints" => {
            "type"=>"http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
           "maximum"=>"500"
          }
        },
        {
           "name"=>"Password"
        }
      ])
    end
  end

end
