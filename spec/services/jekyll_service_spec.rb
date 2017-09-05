require 'rails_helper'
require 'support/odlifier_licence_mock'


describe JekyllService, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'odlifier licence mock'

  let(:user) { create(:user) }
  let(:path) { get_fixture_file('test-data.csv') }


  context "for a dataset" do
    it "creates a file in Github" do
      dataset = build(:dataset, user: user, repo: "repo")
      repo = double(GitData)
      expect(repo).to receive(:add_file).once.with("my-file", "File contents")
      jekyll_service = JekyllService.new(dataset, repo)

      jekyll_service.add_file_to_repo("my-file", "File contents")
    end

    it "creates a file in a folder in Github" do
      dataset = build(:dataset, user: user, repo: "repo")
      repo = double(GitData)
      expect(repo).to receive(:add_file).with("folder/my-file", "File contents")
      jekyll_service = JekyllService.new(dataset, repo)
      jekyll_service.add_file_to_repo("folder/my-file", "File contents")
    end

    it "updates a file in Github" do
      dataset = build(:dataset, user: user, repo: "repo")
      repo = dataset.instance_variable_get(:@repo)

      expect(repo).to receive(:update_file).with("my-file", "File contents")
      jekyll_service = JekyllService.new(dataset, repo)
      jekyll_service.update_file_in_repo("my-file", "File contents")
    end

    it 'waits for the page build to finish then creates certificate' do
      dataset = build(:dataset, user: user, repo: "repo")

      jekyll_service = JekyllService.new(dataset, nil)

      expect(jekyll_service).to receive(:gh_pages_building?).once.and_return(false)
      expect_any_instance_of(Object).to receive(:sleep).with(5)
      expect(jekyll_service).to receive(:gh_pages_building?).once.and_return(true)
      expect(jekyll_service).to receive(:create_jekyll_files).once
      expect(jekyll_service).to receive(:push_to_github).once
      expect(jekyll_service).to receive(:create_certificate).once

      jekyll_service.create_public_views(dataset)
    end

    it 'creates a certificate' do
      @certificate_url = 'http://staging.certificates.theodi.org/en/datasets/162441/certificate.json'
      dataset = build(:dataset, user: user, repo: "repo")

      repo = double(GitData)
      jekyll_service = JekyllService.new(dataset, repo)

      allow(dataset).to receive(:full_name) { "theodi/blockchain-and-distributed-technology-landscape-research" }
      allow(dataset).to receive(:gh_pages_url) { "http://theodi.github.io/blockchain-and-distributed-technology-landscape-research" }

      factory = double(CertificateFactory::Certificate)

      expect(CertificateFactory::Certificate).to receive(:new).with(dataset.gh_pages_url) {
        factory
      }

      expect(factory).to receive(:generate) {{ success: 'pending' }}
      expect(factory).to receive(:result) {{ certificate_url: @certificate_url }}
      expect(jekyll_service).to receive(:add_certificate_url).with(@certificate_url, dataset)

      jekyll_service.create_certificate(dataset)
    end

    it 'adds the badge url to the repo' do

      expect_any_instance_of(Dataset).to receive(:check_repo)

      dataset = create(:dataset, user: user, repo: "repo")
      repo = double(GitData)
      jekyll_service = JekyllService.new(dataset, repo)

      @certificate_url = 'http://staging.certificates.theodi.org/en/datasets/162441/certificate.json'

      expect_any_instance_of(JekyllService).to receive(:update_file_in_repo).with('_config.yml', {
        "data_source" => ".",
        "update_frequency" => dataset.frequency,
        "certificate_url" => "http://staging.certificates.theodi.org/en/datasets/162441/certificate/badge.js"
      }.to_yaml)
      expect(jekyll_service).to receive(:push_to_github)

      jekyll_service.add_certificate_url(@certificate_url, dataset)

      expect(dataset.certificate_url).to eq('http://staging.certificates.theodi.org/en/datasets/162441/certificate')
    end
  end

  context "for a dataset file" do
    context "add_to_github" do
      before(:each) do
        @tempfile = Rack::Test::UploadedFile.new(path, "text/csv")
        @storage_key = 'test-data.csv'
        @file = create(:dataset_file, title: "Example", file: @tempfile, storage_key: @storage_key)

        @dataset = build(:dataset, repo: "my-repo", user: user)
        @dataset.dataset_files << @file
        @jekyll_service = JekyllService.new(@dataset, nil)
      end

      it "adds data file to Github" do
        expect(@jekyll_service).to receive(:add_file_to_repo).with("data/example.csv", File.read(path))
        @jekyll_service.add_to_github(@file)
      end

      it "adds jekyll file to Github" do
        expect(@jekyll_service).to receive(:add_file_to_repo).with("data/example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
        @jekyll_service.add_jekyll_to_github(@file.filename)
      end
    end

    context "update_in_github" do

      before(:each) do

        @filename = 'valid-schema.csv'
        storage_key = @filename
        @url_for_data_file = url_with_stubbed_get_for_storage_key(storage_key, @filename)
        @tempfile = get_string_io_from_fixture_file(@filename)
        @file = build(:dataset_file, title: "Example", file: @tempfile, storage_key: storage_key, filename: @filename)
        @jekyll_service = JekyllService.new(@dataset, nil)
        @dataset = build(:dataset, repo: "my-repo", user: user, dataset_files: [@file])
      end

      it "updates a data file in Github" do
        expect(@jekyll_service).to receive(:update_file_in_repo).with("data/#{@filename}", @tempfile.read)
        @jekyll_service.update_in_github(@file.filename, @tempfile)
      end

      it "updates a jekyll file in Github" do
        expect(@jekyll_service).to receive(:update_file_in_repo).with("data/example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
        @jekyll_service.update_jekyll_in_github('example.csv')
      end
    end
  end

  context "sends the correct files to Github" do

    let(:filename) { 'test-data.csv' }
    let(:storage_key) { filename }
    let(:string_io_for_data_file) { get_string_io_from_fixture_file(filename) }

    it "without a schema" do

      dataset = build :dataset, user: user,
        dataset_files: [
          create(:dataset_file, filename: filename, file: string_io_for_data_file, storage_key: storage_key)
        ]

      jekyll_service = JekyllService.new(dataset, nil)

      allow_any_instance_of(RepoService).to receive(:add_file).and_return {}

      expect(jekyll_service).to receive(:add_file_to_repo).with("data/my-awesome-dataset.csv", File.open(File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("datapackage.json", jekyll_service.create_json_datapackage) { {content: {} }}

      expect(jekyll_service).to receive(:add_file_to_repo).with("data/my-awesome-dataset.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_config.yml", dataset.config)
      expect(jekyll_service).to receive(:add_file_to_repo).with("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("js/papaparse.min.js", File.open(File.join(Rails.root, "extra", "js", "papaparse.min.js")).read)

      jekyll_service.create_data_files
      jekyll_service.create_jekyll_files
    end

    it "with a schema" do
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      data_file = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')
      url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)

      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', url_for_schema, user).create_dataset_file_schema

      dataset_file = create(:dataset_file, dataset_file_schema: dataset_file_schema, file: Rack::Test::UploadedFile.new(data_file, "text/csv"), storage_key: 'valid-schema.csv')

      dataset = build(:dataset, user: user, dataset_files: [dataset_file])

      jekyll_service = JekyllService.new(dataset, nil)
      allow_any_instance_of(RepoService).to receive(:add_file).with(:param_one, :param_two).and_return { nil }

      expect(jekyll_service).to receive(:add_file_to_repo).with("data/my-awesome-dataset.csv", File.open(data_file).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("datapackage.json", jekyll_service.create_json_datapackage) { {content: {} }}
      expect(jekyll_service).to receive(:add_file_to_repo).with("#{dataset_file.dataset_file_schema.name.downcase.parameterize}.schema.json", dataset_file.dataset_file_schema.schema)

      expect(jekyll_service).to receive(:add_file_to_repo).with("data/my-awesome-dataset.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_config.yml", dataset.config)
      expect(jekyll_service).to receive(:add_file_to_repo).with("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
      expect(jekyll_service).to receive(:add_file_to_repo).with("js/papaparse.min.js", File.open(File.join(Rails.root, "extra", "js", "papaparse.min.js")).read)

      jekyll_service.create_data_files
      jekyll_service.create_jekyll_files
    end
  end

  it "generates the correct datapackage contents" do
    file = create(:dataset_file, title: "My Awesome File",
                                 description: "My Awesome File Description")
    dataset = build(:dataset, name: "My Awesome Dataset",
                              description: "My Awesome Description",
                              user: user,
                              license: "OGL-UK-3.0",
                              publisher_name: "Me",
                              publisher_url: "http://www.example.com",
                              repo: "repo",
                              dataset_files: [
                                file
                              ])

    jekyll_service = JekyllService.new(dataset, nil)
    datapackage = JSON.parse(jekyll_service.create_json_datapackage)

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
    jekyll_service = JekyllService.new(dataset, nil)
    expect(jekyll_service).to receive(:add_file_to_repo).with("datapackage.json", jekyll_service.create_json_datapackage)
    jekyll_service.create_json_datapackage_and_add_to_repo
  end

  it "updates the datapackage" do
    dataset = create(:dataset)
    jekyll_service = JekyllService.new(dataset, nil)
    expect_any_instance_of(JekyllService).to receive(:update_file_in_repo).with("datapackage.json", jekyll_service.create_json_datapackage)
    jekyll_service.update_datapackage
  end

  context "schemata" do

    let(:good_schema_path) { File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json') }
    let(:bad_schema_path) { File.join(Rails.root, 'spec', 'fixtures', 'schemas/bad-schema.json') }
    let(:data_file) { File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv') }

    it 'is unhappy with a duff schema' do
      bad_schema = url_for_schema_with_stubbed_get_for(bad_schema_path)
      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', bad_schema, user).create_dataset_file_schema
      expect { create(:dataset_file, dataset_file_schema: dataset_file_schema, file: Rack::Test::UploadedFile.new(data_file, "text/csv"), storage_key: 'valid-schema.csv') }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Schema is not valid')
    end

    it 'is happy with a good schema' do
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      schema = url_with_stubbed_get_for(path)
      dataset = build(:dataset)

      expect(dataset.valid?).to be true

      good_schema = url_for_schema_with_stubbed_get_for(good_schema_path)
      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', good_schema, user).create_dataset_file_schema
      create(:dataset_file, dataset_file_schema: dataset_file_schema, file: Rack::Test::UploadedFile.new(data_file, "text/csv"), storage_key: 'valid-schema.csv')

      expect(DatasetFile.count).to be 1
    end

    it 'adds the schema to the datapackage' do
      url_for_schema = url_for_schema_with_stubbed_get_for(good_schema_path)
      @dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', url_for_schema, user).create_dataset_file_schema
      @dataset_file = create(:dataset_file, dataset_file_schema: @dataset_file_schema, file: Rack::Test::UploadedFile.new(data_file, "text/csv"), storage_key: 'valid-schema.csv')
      @dataset = build(:dataset, user: user, dataset_files: [@dataset_file])

      jekyll_service = JekyllService.new(@dataset, nil)

      datapackage = JSON.parse jekyll_service.create_json_datapackage

      first_resource = datapackage['resources'].first

      expect(first_resource['schema']['name']).to eq('schema-name')
      expect(first_resource['schema']['description']).to eq('schema-name-description')

      compare_schemas_after_processing(first_resource['schema']['fields'], example_hash)
    end
  end

  def example_hash
    Array.new([
        {
          "name" => "Username",
          "type"=>"string",
          "format"=>"default",
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
          "type"=>"string",
           "format"=>"default",
          "constraints" => {
            "type"=>"http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
            "minimum"=>"13",
            "maximum"=>"99"
          }
        },
        {
           "name"=>"Height",
           "type"=>"string",
           "format"=>"default",
           "constraints" => {
             "type"=>"http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
             "minimum"=>"20"
           }
        },
        {
          "name"=>"Weight",
          "type"=>"string",
          "format"=>"default",
          "constraints" => {
            "type"=>"http://www.w3.org/2001/XMLSchema#nonNegativeInteger",
            "maximum"=>"500"
          }
        },
        {
          "name"=>"Password",
          "type"=>"string",
          "format"=>"default",
        }
      ])
  end

  context 'csv-on-the-web schema' do

    let(:good_schema_path) { File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'csv-on-the-web-schema.json') }
    let(:bad_schema_path) { File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'duff-csv-on-the-web-schema.json') }
    let(:data_file) { File.join(Rails.root, 'spec', 'fixtures', 'valid-cotw.csv') }

    it 'is unhappy with a duff schema' do

      bad_schema = url_with_stubbed_get_for(bad_schema_path)

      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', bad_schema, user).create_dataset_file_schema
      expect { create(:dataset_file, dataset_file_schema: dataset_file_schema, file: Rack::Test::UploadedFile.new(data_file, "text/csv")) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Schema is not valid')
    end

    it 'does not add the schema to the datapackage' do

      schema = url_with_stubbed_get_for(good_schema_path)
      dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', schema, user).create_dataset_file_schema

      file = create(:dataset_file, dataset_file_schema: dataset_file_schema,
                                   file: Rack::Test::UploadedFile.new(data_file, "text/csv"),
                                   filename: "example.csv",
                                   title: "My Awesome File",
                                   description: "My Awesome File Description")

      dataset = build(:dataset, dataset_files: [file])
      jekyll_service = JekyllService.new(dataset, nil)
      datapackage = JSON.parse jekyll_service.create_json_datapackage

      expect(datapackage['resources'].first['schema']).to eq(nil)
    end

    context 'csv-on-the-web schema' do

      let(:csv2rest_hash) {

         {
        "/people/sam" => { "@id" => "/people/sam", "person" => "sam", "age" => 42, "@type" => "/people" },
          "/people" => [
             { "@id" => "/people/sam", "url" => "/people/sam" },
             { "@id" => "/people/stu", "url" => "/people/stu" }
            ],
            "/" => [ { "@type" => "/people",  "url" => "/people" } ],
          "/people/stu" => { "@id" => "/people/stu", "person" => "stu", "age" => 34, "@type" => "/people" }
          }
      }

      it "creates JSON files on GitHub when using a CSVW schema" do

        @user = create(:user, name: "user-mcuser", email: "user@user.com")
        allow_any_instance_of(Octokit::Client).to receive(:repository?) { false }
        allow(Csv2rest).to receive(:generate) { csv2rest_hash}

        good_schema_cotw_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/csv-on-the-web-schema.json')
        url_for_schema = url_with_stubbed_get_for(good_schema_cotw_path)
        dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', url_for_schema, @user).create_dataset_file_schema
        dataset = build(:dataset, user: @user)

        dataset_file = create(:dataset_file, dataset_file_schema: dataset_file_schema,
                                     dataset: dataset,
                                     file: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'valid-cotw.csv'), "text/csv"),
                                     filename: "valid-cotw.csv",
                                     storage_key: "valid-cotw.csv",
                                     title: "My Awesome File",
                                     description: "My Awesome File Description")

        dataset.dataset_files << dataset_file

        jekyll_service = JekyllService.new(dataset, 'repo')
        allow_any_instance_of(RepoService).to receive(:add_file).and_return { "ROOORARRRR" }

        expect(jekyll_service).to receive(:add_file_to_repo).with("data/my-awesome-file.csv", File.open(File.join(Rails.root, 'spec', 'fixtures', 'valid-cotw.csv')).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("datapackage.json", jekyll_service.create_json_datapackage) { {content: {} }}
        expect(jekyll_service).to receive(:add_file_to_repo).with("#{dataset_file.dataset_file_schema.name.downcase.parameterize}.schema.json", dataset_file.dataset_file_schema.schema)
        expect(jekyll_service).to receive(:add_file_to_repo).with("people/sam.json", '{"@id":"/people/sam","person":"sam","age":42,"@type":"/people"}')
        expect(jekyll_service).to receive(:add_file_to_repo).with("people.json", '[{"@id":"/people/sam","url":"people/sam.json"},{"@id":"/people/stu","url":"people/stu.json"}]')
        expect(jekyll_service).to receive(:add_file_to_repo).with("index.json", '[{"@type":"/people","url":"people.json"}]')
        expect(jekyll_service).to receive(:add_file_to_repo).with("people/stu.json", '{"@id":"/people/stu","person":"stu","age":34,"@type":"/people"}')

        expect(jekyll_service).to receive(:add_file_to_repo).with("data/my-awesome-file.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("_config.yml", dataset.config)
        expect(jekyll_service).to receive(:add_file_to_repo).with("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("js/papaparse.min.js", File.open(File.join(Rails.root, "extra", "js", "papaparse.min.js")).read)

        expect(jekyll_service).to receive(:add_file_to_repo).with("people.md", File.open(File.join(Rails.root, "extra", "html", "api-list.md")).read)
        expect(jekyll_service).to receive(:add_file_to_repo).with("people/stu.md", File.open(File.join(Rails.root, "extra", "html", "api-item.md")).read)

        expect(jekyll_service).to receive(:add_file_to_repo).with("people/sam.md", File.open(File.join(Rails.root, "extra", "html", "api-item.md")).read)
        jekyll_service.create_data_files
        jekyll_service.create_jekyll_files
      end
    end
  end
end
