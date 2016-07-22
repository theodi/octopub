require 'spec_helper'

describe Dataset do

  before(:each) do
    @user = create(:user, name: "user-mcuser", email: "user@user.com")
    allow_any_instance_of(Octokit::Client).to receive(:repository?) { false }
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

  it "returns an error if the repo already exists" do
    expect_any_instance_of(Octokit::Client).to receive(:repository?).with("user-mcuser/my-awesome-dataset") { true }

    dataset = build(:dataset, name: "My Awesome Dataset",
                     description: "An awesome dataset",
                     publisher_name: "Awesome Inc",
                     publisher_url: "http://awesome.com",
                     license: "OGL-UK-3.0",
                     frequency: "One-off",
                     user: @user)

    expect(dataset).to_not be_valid
  end

  it "creates a repo in Github" do
    name = "My Awesome Dataset"
    html_url = "http://github.com/#{@user.name}/#{name.parameterize}"

    dataset = build(:dataset, :with_callback, user: @user, name: name)

    expect(GitData).to receive(:create).with(@user.github_username, name, client: a_kind_of(Octokit::Client)) {
      obj = double(GitData)
      expect(obj).to receive(:html_url) { html_url }
      expect(obj).to receive(:name) { name.parameterize }
      expect(obj).to receive(:full_name) { "#{@user.name.parameterize}/#{name.parameterize}" }
      obj
    }

    expect(dataset).to receive(:commit)

    dataset.save
    dataset.reload

    expect(dataset.repo).to eq(name.parameterize)
    expect(dataset.url).to eq(html_url)
  end

  it "creates a repo with an organization" do
    name = "My Awesome Dataset"
    dataset = build(:dataset, :with_callback, user: @user, name: name, owner: "my-cool-organization")

    expect(GitData).to receive(:create).with('my-cool-organization', name, client: a_kind_of(Octokit::Client)) {
      obj = double(GitData)
      expect(obj).to receive(:html_url) { nil }
      expect(obj).to receive(:name) { name.parameterize }
      expect(obj).to receive(:full_name) { "my-cool-organization/#{name.parameterize}" }
      obj
    }

    expect(dataset).to receive(:commit)

    dataset.save
  end

  it "deletes a repo in github" do
    dataset = create(:dataset, user: @user, owner: "foo-bar")
    repo = dataset.instance_variable_get(:@repo)

    expect(repo).to receive(:delete)

    dataset.destroy
  end

  it "sets the user's avatar" do
    dataset = build(:dataset, :with_avatar_callback, user: @user)

    expect(@user).to receive(:avatar) {
      'http://example.com/avatar.png'
    }

    dataset.save

    expect(dataset.owner_avatar).to eq('http://example.com/avatar.png')
  end

  it "sets the owner's avatar" do
    dataset = build(:dataset, :with_avatar_callback, user: @user, owner: 'my-cool-organization')

    expect(Rails.configuration.octopub_admin).to receive(:organization).with('my-cool-organization') {
      double = double(Sawyer::Resource)
      expect(double).to receive(:avatar_url) {
        'http://example.com/my-cool-organization.png'
      }
      double
    }

    dataset.save

    expect(dataset.owner_avatar).to eq('http://example.com/my-cool-organization.png')
  end

  context('#fetch_repo') do

    before(:each) do
      @dataset = create(:dataset, user: @user, repo: "repo")

      @double = double(GitData)

      expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) {
        @double
      }
    end

    it "gets a repo from Github" do
      expect(@dataset).to receive(:check_for_schema)
      @dataset.fetch_repo
      expect(@dataset.instance_variable_get(:@repo)).to eq(@double)
    end

    it "gets a schema" do
      stub_request(:get, @dataset.schema_url).to_return(body: File.read(File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')))

      @dataset.fetch_repo

      expect(@dataset.schema).to eq('http://user-mcuser.github.io/repo/schema.json')
    end

    it 'returns nil if there is no schema present' do
      @dataset.fetch_repo

      expect(@dataset.schema).to be_nil
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

  context "sends the correct files to Github" do
    it "without a schema" do
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
      expect(dataset).to receive(:create_contents).with("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
      expect(dataset).to receive(:create_contents).with("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)

      dataset.create_files
    end

    it "with a schema" do
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')

      dataset = build :dataset, user: @user,
                                dataset_files: [
                                  create(:dataset_file)
                                ],
                                schema: fake_file(schema_path)

      expect(dataset).to receive(:create_contents).with("datapackage.json", dataset.datapackage) { { content: {} }}
      expect(dataset).to receive(:create_contents).with("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
      expect(dataset).to receive(:create_contents).with("_config.yml", dataset.config)
      expect(dataset).to receive(:create_contents).with("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
      expect(dataset).to receive(:create_contents).with("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
      expect(dataset).to receive(:create_contents).with("schema.json", File.open(schema_path).read)

      dataset.create_files
    end
  end

  it "generates the correct datapackage contents" do
    file = create(:dataset_file, title: "My Awesome File",
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
      "name" => "My Awesome File",
      "mediatype" => "text/csv",
      "description" => "My Awesome File Description",
      "path" => "data/my-awesome-file.csv"
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
      schema = fake_file(path)
      dataset = build(:dataset, schema: schema)

      expect(dataset.valid?).to be false
      expect(dataset.errors.messages[:schema].first).to eq 'is invalid'
    end

    it 'is happy with a good schema' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      schema = fake_file(path)
      dataset = build(:dataset, schema: schema)

      expect(dataset.valid?).to be true
    end

    it 'adds the schema to the datapackage' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      schema = fake_file(path)
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

  context 'csv-on-the-web schema' do
    it 'is unhappy with a duff schema' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/duff-csv-on-the-web-schema.json')
      schema = fake_file(path)
      dataset = build(:dataset, schema: schema)

      expect(dataset.valid?).to be false
      expect(dataset.errors.messages[:schema].first).to eq 'is invalid'
    end

    it 'does not add the schema to the datapackage' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/csv-on-the-web-schema.json')
      schema = fake_file(path)
      file = create(:dataset_file, filename: "example.csv",
                                   title: "My Awesome File",
                                   description: "My Awesome File Description")

      dataset = build(:dataset, schema: schema, dataset_files: [file])
      datapackage = JSON.parse dataset.datapackage

      expect(datapackage['resources'].first['schema']).to eq(nil)
    end

    it "creates JSON files on GitHub when using a CSVW schema" do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/csv-on-the-web-schema.json')
      schema = fake_file(path)
      dataset = build :dataset, schema: schema

      file = create(:dataset_file, dataset: dataset,
                                   file: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'valid-cotw.csv'), "text/csv"),
                                   filename: "valid-cotw.csv",
                                   title: "My Awesome File",
                                   description: "My Awesome File Description")

      dataset.dataset_files << file

      expect(dataset).to receive(:create_contents).with("datapackage.json", dataset.datapackage) { { content: {} }}
      expect(dataset).to receive(:create_contents).with("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
      expect(dataset).to receive(:create_contents).with("_config.yml", dataset.config)
      expect(dataset).to receive(:create_contents).with("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
      expect(dataset).to receive(:create_contents).with("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
      expect(dataset).to receive(:create_contents).with("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
      expect(dataset).to receive(:create_contents).with("schema.json", File.open(path).read)

      expect(dataset).to receive(:create_contents).with("people/sam.json", '{"@id":"/people/sam","person":"sam","age":42,"@type":"/people"}')
      expect(dataset).to receive(:create_contents).with("people/sam.md", File.open(File.join(Rails.root, "extra", "html", "api-item.md")).read)
      expect(dataset).to receive(:create_contents).with("people.json", '[{"@id":"/people/sam","url":"people/sam.json"},{"@id":"/people/stu","url":"people/stu.json"}]')
      expect(dataset).to receive(:create_contents).with("people.md", File.open(File.join(Rails.root, "extra", "html", "api-list.md")).read)
      expect(dataset).to receive(:create_contents).with("index.json", '[{"@type":"/people","url":"people.json"}]')
      expect(dataset).to receive(:create_contents).with("people/stu.json", '{"@id":"/people/stu","person":"stu","age":34,"@type":"/people"}')
      expect(dataset).to receive(:create_contents).with("people/stu.md", File.open(File.join(Rails.root, "extra", "html", "api-item.md")).read)

      dataset.create_files
    end

  end

  context 'creating certificates' do

    before(:each) do
      @dataset = create(:dataset)
      @certificate_url = 'http://staging.certificates.theodi.org/en/datasets/162441/certificate.json'
      allow(@dataset).to receive(:full_name) { "theodi/blockchain-and-distributed-technology-landscape-research" }
      allow(@dataset).to receive(:gh_pages_url) { "http://theodi.github.io/blockchain-and-distributed-technology-landscape-research" }
    end

    it 'waits for the page build to finish' do
      allow_any_instance_of(User).to receive(:octokit_client) {
        client = double(Octokit::Client)
        allow(client).to receive(:pages).with(@dataset.full_name) {
          OpenStruct.new(status: 'pending')
        }
        client
      }

      expect(@dataset).to receive(:retry_certificate)

      @dataset.send :build_certificate
    end

    it 'retries a certificate' do
      expect_any_instance_of(Object).to receive(:sleep).with(5)
      expect(@dataset).to receive(:build_certificate)

      @dataset.send :retry_certificate
    end

    it 'creates the certificate when build is complete' do
      allow_any_instance_of(User).to receive(:octokit_client) {
        client = double(Octokit::Client)
        allow(client).to receive(:pages).with(@dataset.full_name) {
          OpenStruct.new(status: 'built')
        }
        client
      }

      expect(@dataset).to receive(:create_certificate)

      @dataset.send :build_certificate
    end

    it 'creates a certificate' do
      factory = double(CertificateFactory::Certificate)

      expect(CertificateFactory::Certificate).to receive(:new).with(@dataset.gh_pages_url) {
        factory
      }

      expect(factory).to receive(:generate) {
        {
          success: 'pending'
        }
      }

      expect(factory).to receive(:result) {
        {
          certificate_url: @certificate_url
        }
      }

      expect(@dataset).to receive(:add_certificate_url).with(@certificate_url)

      @dataset.send(:create_certificate)
    end

    it 'adds the badge url to the repo' do
      expect(@dataset).to receive(:fetch_repo)
      expect(@dataset).to receive(:update_contents).with('_config.yml', {
        "data_source" => ".",
        "update_frequency" => "One-off",
        "certificate_url" => "http://staging.certificates.theodi.org/en/datasets/162441/certificate/badge.js"
      }.to_yaml)
      expect(@dataset).to receive(:push_to_github)

      @dataset.send(:add_certificate_url, @certificate_url)

      expect(@dataset.certificate_url).to eq('http://staging.certificates.theodi.org/en/datasets/162441/certificate')
    end

  end

end
