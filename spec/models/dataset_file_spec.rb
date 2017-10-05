# == Schema Information
#
# Table name: dataset_files
#
#  id                     :integer          not null, primary key
#  title                  :string
#  filename               :string
#  mediatype              :string
#  dataset_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  description            :text
#  file_sha               :text
#  view_sha               :text
#  dataset_file_schema_id :integer
#  storage_key            :string
#

require 'rails_helper'

describe DatasetFile, vcr: { :match_requests_on => [:host, :method] } do

  let(:filename) { 'test-data.csv' }
  let(:storage_key) { "uploads/#{SecureRandom.uuid}/#{filename}" }

  before(:each) do
    @user = create(:user)
    @path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
    @file = create(:dataset_file, title: "Example", storage_key: storage_key)

  end

  it "generates the correct urls" do

    dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [@file])

    expect(@file.github_url).to eq("http://github.com/#{@user.github_username}/my-repo/data/example.csv")
    expect(@file.gh_pages_url).to eq("http://#{@user.github_username}.github.io/my-repo/data/example.csv")
  end

  it "generates a filename" do
    file = create(:dataset_file, title: "Something Terrible")
    expect(file.filename).to eq("something-terrible.csv")
  end

  it "errors without a title" do
    file = build(:dataset_file, title: nil)
    expect(file.valid?).to eq(false)
  end

  context "self.create" do
    context "with uploaded file" do

      before(:each) do
        path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
        @tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

        @file = {
          "title" => 'My File',
          "file" => @tempfile,
          "description" => 'A description',
          "storage_key" => @storage_key
        }
      end

      it "creates a file" do
        file = DatasetFile.create(@file)

        expect(file.title).to eq(@file["title"])
        expect(file.filename).to eq("my-file.csv")
        expect(file.description).to eq(@file["description"])
      end
    end

    context "with file at the end of a URL" do
      before(:each) do
        @url = "https://cdn.rawgit.com/theodi/hot-drinks/gh-pages/hot-drinks.csv"

        @file = {
          "title" => 'Hot Drinks',
          "file" => @url,
          "description" => 'WARNING: Contents may be hot'
        }
      end
      it "creates a file" do
        file = DatasetFile.create(@file)

        expect(file.title).to eq(@file["title"])
        expect(file.filename).to eq("hot-drinks.csv")
        expect(file.description).to eq(@file["description"])
      end
    end

    context "with file and a storage key" do
      it "creates a file" do
        filename = 'test-data.csv'
        storage_key = filename
        url_for_data_file = url_with_stubbed_get_for_storage_key(storage_key, filename)

        @file = {
          "title" => 'Hot Drinks',
          "file" => url_for_data_file,
          "description" => 'WARNING: Contents may be hot',
          "storage_key" => storage_key
        }

        file = DatasetFile.create(@file)

        expect(file.title).to eq(@file["title"])
        expect(file.filename).to eq("hot-drinks.csv")
        expect(file.description).to eq(@file["description"])
      end
    end
  end

  context "update_file" do
    it "updates a file when given a URL" do
      file = create(:dataset_file, title: 'Test Data')
      path = File.join(Rails.root, storage_key)
      url = "https://cdn.rawgit.com/theodi/hot-drinks/gh-pages/hot-drinks.csv"

       new_file = {
          "id" => file.id,
          "title" => 'Hot Drinks',
          "file" => url,
          "description" => 'WARNING: Contents may be hot',
        }

      file.update_file(new_file)
      expect(file.filename).to eq('test-data.csv')
      expect(file.description).to eq(new_file["description"])
    end

    it "updates a file when given a storage key" do
      file = create(:dataset_file, title: 'Test Data')

      filename = 'test-data.csv'
      storage_key = filename
      url_for_data_file = url_with_stubbed_get_for_storage_key(storage_key, filename)
      new_file = {
        "id" => file.id,
        "title" => 'Hot Drinks',
        "file" => url_for_data_file,
        "description" => 'WARNING: Contents may be hot',
        "storage_key" => storage_key
      }
      file.update_file(new_file)

      expect(file.filename).to eq('test-data.csv')
      expect(file.storage_key).to eq(storage_key)
      expect(file.description).to eq(new_file["description"])
    end

    it "updates a file when given a File" do
      file = create(:dataset_file, title: 'Test Data')
      storage_key = 'spec/fixtures/test-data0.csv'
      path = File.join(Rails.root, storage_key)
      tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

      new_file = {
        "id" => file.id,
        "file" => tempfile,
        "description" => 'A new description',
        "storage_key" => storage_key
      }

      file.update_file(new_file)

      expect(file.filename).to eq('test-data.csv')
      expect(file.storage_key).to eq(storage_key)
      expect(file.description).to eq(new_file["description"])
    end

    it "only updates the referenced file if a file is present" do

      file = create(:dataset_file)

      new_file = {
        "id" => file.id,
        "title" => 'My File',
        "description" => 'A new description',
      }

      expect_any_instance_of(JekyllService).to_not receive(:update_in_github)

      file.update_file(new_file)

      expect(file.description).to eq(new_file["description"])
    end

  end

  context 'with schema' do

    before(:each) do
      @dataset = build(:dataset)
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      stubbed_schema_url = url_with_stubbed_get_for(schema_path)
      @dataset_file_schema = create(:dataset_file_schema, url_in_repo: stubbed_schema_url)
      @storage_key ||= 'test-data.csv'

    end

    it 'validates against a schema with good data' do
      storage_key = 'valid-schema.csv'
      file_path = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')
      file = build(:dataset_file,  dataset_file_schema: @dataset_file_schema,
                                   filename: "example.csv",
                                   title: "My Awesome File",
                                   description: "My Awesome File Description",
                                   file: Rack::Test::UploadedFile.new(file_path, "text/csv"),
                                   storage_key: storage_key,
                                   dataset: @dataset)
      @dataset.dataset_files << file

      expect(file.valid?).to eq(true)
      expect(@dataset.valid?).to eq(true)
    end

    it 'returns the schema name' do
      schema_name = Faker::Name.unique.name
      dataset_file = build(:dataset_file,  dataset_file_schema: build(:dataset_file_schema, name: schema_name))
      expect(dataset_file.schema_name).to eq schema_name
    end

    it 'does not validate against a good schema with bad data' do

      storage_key = 'invalid-schema.csv'
      file = build(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: "example.csv",
                                  title: "My Awesome File",
                                  description: "My Awesome File Description",
                                  storage_key: storage_key,
                                 # file: Rack::Test::UploadedFile.new(file_path, "text/csv"),
                                  dataset: @dataset)

      @dataset.dataset_files << file

      expect(file.valid?).to eq(false)
      expect(@dataset.valid?).to eq(false)
    end

    it 'does not validate against a bad schema with good data' do

      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/bad-schema.json')
      stubbed_schema_url = url_with_stubbed_get_for(schema_path)
      @dataset_file_schema = create(:dataset_file_schema, url_in_repo: stubbed_schema_url)

      storage_key = 'valid-schema.csv'

      file = build(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: "example.csv",
                                  title: "My Awesome File",
                                  description: "My Awesome File Description",
                        #          file: Rack::Test::UploadedFile.new(file_path, "text/csv"),
                                  storage_key: storage_key,
                                  dataset: @dataset)

      @dataset.dataset_files << file

      expect(file.valid?).to eq(false)
      expect(@dataset.valid?).to eq(false)
    end

  end

  context 'with csv-on-the-web schema' do
    before :each do
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/csv-on-the-web-schema.json')
      stubbed_schema_url = url_with_stubbed_get_for(schema_path)
      @dataset = build(:dataset)
      @dataset_file_schema = build(:dataset_file_schema, url_in_repo: stubbed_schema_url, csv_on_the_web_schema: true, schema: File.read(schema_path))
    end

    it 'validates with good data' do
      storage_key = 'valid-cotw.csv'
      file_path = File.join(Rails.root, 'spec', 'fixtures', 'valid-cotw.csv')
      file = build(:dataset_file,  dataset_file_schema: @dataset_file_schema,
                                   filename: "people.csv",
                                   title: "People",
                                   description: "People make the world go round",
                                   file: Rack::Test::UploadedFile.new(file_path, "text/csv"),
                                   storage_key: storage_key,
                                   dataset: @dataset)
      @dataset.dataset_files << file

      expect(@dataset_file_schema.is_schema_otw?).to be true
      expect(file.valid?).to eq(true)
      expect(@dataset.valid?).to eq(true)
    end

    it 'does not validate with bad data' do
      file_path = File.join(Rails.root, 'spec', 'fixtures', 'invalid-cotw.csv')
      storage_key = 'invalid-cotw.csv'
      file = build(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: "people.csv",
                                  title: "People",
                                  description: "People are terrible",
                                  file: Rack::Test::UploadedFile.new(file_path, "text/csv"),
                                  storage_key: storage_key,
                                  dataset: @dataset)

      @dataset.dataset_files << file

      expect(@dataset_file_schema.is_schema_otw?).to be true
      expect(file.valid?).to eq(false)
      expect(@dataset.valid?).to eq(false)
    end
  end

  context 'with multiple csv-on-the-web files' do
    before :each do
      # This file has schemas for hats and shoes, hats.csv and shoes.csv
      # The hats.csv fixture file IS DUFF and therefore should fail validation
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/multiple-csvs-on-the-web-schema.json')
      stubbed_schema_url = url_with_stubbed_get_for(schema_path)
      @dataset_file_schema = build(:dataset_file_schema, url_in_repo: stubbed_schema_url, csv_on_the_web_schema: true, schema: File.read(schema_path))
      @dataset = build(:dataset)
    end

    it 'validates with good data' do
      file_path = File.join(Rails.root, 'spec', 'fixtures', 'shoes-cotw.csv')
      storage_key = 'shoes-cotw.csv'
      file = build(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: "shoes.csv",
                                  title: "Shoes",
                                  description: "Shoes and glasses",
                                  file: Rack::Test::UploadedFile.new(file_path, "text/csv"),
                                  storage_key: storage_key,
                                  dataset: @dataset)
      @dataset.dataset_files << file

      expect(file.valid?).to eq(true)
      expect(@dataset.valid?).to eq(true)
    end

    it 'does not validate with duff data' do
      file_path = File.join(Rails.root, 'spec', 'fixtures', 'hats-cotw.csv')
      file_name = 'hats-cotw.csv'
      storage_key = "uploads/#{file_name}"
      file = build(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: file_name,
                                  title: "Hats",
                                  description: "All around my hat",
                                  file: Rack::Test::UploadedFile.new(file_path, "text/csv"),
                                  storage_key: storage_key,
                                  dataset: @dataset)

      @dataset.dataset_files << file

      expect(file.valid?).to eq(false)
      expect(@dataset.valid?).to eq(false)
    end

  end

  context 'with a non-csv file' do
    before(:each) do
      @dataset = build(:dataset)
      path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      @file = Rack::Test::UploadedFile.new(path, "text/csv")
      storage_key = 'schemas/good-schema.json'
    end

    it 'errors on create' do
      file = build(:dataset_file, filename: "example.csv",
                                   title: "My Awesome File",
                                   description: "My Awesome File Description",
                                   file: get_string_io_from_fixture_file('datapackage.json'),
                                   storage_key: 'datapackage.json',
                                   dataset: @dataset)

      @dataset.dataset_files << file

      expect(file.valid?).to eq(false)
      expect(file.errors.messages[:file].first).to eq('does not appear to be a valid CSV. Please check your file and try again.')
      expect(@dataset.valid?).to eq(false)
    end

    it 'errors on create with garbage' do

      allow(CSV).to receive(:parse).and_raise("boom")

      file = build(:dataset_file, filename: "example.csv",
                                   title: "My Awesome File",
                                   description: "My Awesome File Description",
                                   file: @file,
                                   storage_key: storage_key,
                                   dataset: @dataset)

      @dataset.dataset_files << file
      expect(file.valid?).to eq(false)
      expect(file.errors.messages[:file].first).to eq('had some problems trying to upload. Please check your file and try again.')
      expect(@dataset.valid?).to eq(false)
    end

    it 'errors on update' do
      # Create a nice working file
      file = create(:dataset_file, title: "Example", storage_key: storage_key)      
      @dataset.dataset_files << file
      @dataset.save

      # Update it with some non-CSV junk
      new_file = {
        "id" => file.id,
        "file" => file,
        "description" => 'A new description',
        "storage_key" => "datapackage.json"
      }

      file.update_file(new_file)
      @dataset.save

      expect(file.valid?).to eq(false)
      expect(file.errors.messages[:file].first).to eq('does not appear to be a valid CSV. Please check your file and try again.')
      expect(@dataset.valid?).to eq(false)
    end
  end
end
