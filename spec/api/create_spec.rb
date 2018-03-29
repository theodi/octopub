require 'rails_helper'

describe 'POST /datasets' do

  before(:each) do
    Sidekiq::Testing.inline!
    @user = create(:user)

    @name = "My cool dataset"
    @description = "This is a description"
    @publisher_name = "Cool inc"
    @publisher_url = "http://example.com"
    @license = "OGL-UK-3.0"
    @frequency = "Monthly"

    allow(RepoService).to receive(:prepare_repo)
    allow_any_instance_of(JekyllService).to receive(:add_to_github) { nil }
    allow_any_instance_of(JekyllService).to receive(:create_data_files) { nil }
    allow_any_instance_of(JekyllService).to receive(:create_jekyll_files) { nil }

    name = 'Test Data'
    description = Faker::Company.bs
    filename = 'test-data.csv'
    @path = File.join(Rails.root, 'spec', 'fixtures', filename)

    @storage_key = "uploads/#{SecureRandom.uuid}/#{filename}"

    allow_any_instance_of(Dataset).to receive(:complete_publishing)

    @repo = double(GitData)

    allow(GitData).to receive(:create).with(@user.github_username, @name, restricted: false, client: a_kind_of(Octokit::Client)) {
      @repo
    }
    allow(GitData).to receive(:find).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
      @repo
    }
    allow_any_instance_of(User).to receive(:github_user) {
      OpenStruct.new(
        avatar_url: "http://www.example.org/avatar2.png"
      )
    }

    @file = {
      :title => name,
      :description => description,
      :file => fixture_file_upload(@path),
      :storage_key => @storage_key
    }
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  pending 'returns a job ID' do
    expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
    expect(@repo).to receive(:name) { 'my-cool-repo' }
    expect(@repo).to receive(:full_name) { 'user-mc-user/my-cool-repo' }
    expect(@repo).to receive(:save)

    allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(@path))

    post '/api/datasets', params: {
      dataset: {
        name: @name,
        description: @description,
        publisher_name: @publisher_name,
        publisher_url: @publisher_url,
        license: @license,
        frequency: @frequency
      },
      file: @file
    },
    headers: { 'Authorization' => "Token token=#{@user.api_key}" }

    expect(Dataset.count).to eq(1)
    expect(@user.datasets.count).to eq(1)
    expect(@user.datasets.first.dataset_files.count).to eq(1)

    json = JSON.parse(response.body)

    expect(json['job_url']).to match /\/api\/jobs\/(.+)\.json/
  end

  it 'errors with an invalid license' do

    allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(@file)
    post '/api/datasets', params: {
      dataset: {
        name: @name,
        description: @description,
        publisher_name: @publisher_name,
        publisher_url: @publisher_url,
        license: 'bogus-license-id',
        frequency: @frequency
      },
      file: @file
    },
    headers: { 'Authorization' => "Token token=#{@user.api_key}" }


    expect(response.code).to eq("400")

    json = JSON.parse(response.body)

    expect(json['error']).to eq('dataset[license] does not have a valid value')
  end

  it 'errors with a missing publisher name' do

    allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(@file)
    post '/api/datasets', params: {
      dataset: {
        name: @name,
        description: @description,
        publisher_url: @publisher_url,
        license: @license,
        frequency: @frequency
      },
      file: @file
    },
    headers: { 'Authorization' => "Token token=#{@user.api_key}" }

    expect(response.code).to eq("400")

    json = JSON.parse(response.body)

    expect(json['error']).to eq('dataset[publisher_name] is missing')
  end

  context('with a schema') do

    before(:each) do
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')
      @schema = url_with_stubbed_get_for(schema_path)

      @filename = 'valid-schema.csv'
      @storage_key = "uploads/#{SecureRandom.uuid}/#{@filename}"
    end

    pending 'creates a dataset sucessfully' do
      expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
      expect(@repo).to receive(:name) { 'my-cool-repo' }
      expect(@repo).to receive(:full_name) { 'user-mc-user/my-cool-repo' }
      expect(@repo).to receive(:save)

      path = File.join(Rails.root, 'spec', 'fixtures', @filename)

      good_schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      stubbed_schema_url = url_with_stubbed_get_for(good_schema_path)

      allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(path))

      file = {
        title: 'My File',
        description: 'My Description',
        file: fixture_file_upload(path),
        storage_key: @storage_key,
        schema_name: 'schema name',
        schema_description: 'schema description',
        schema: stubbed_schema_url
      }

      post '/api/datasets', params: {
        dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
        },
        file: file
      },
      headers: { 'Authorization' => "Token token=#{@user.api_key}" }

      expect(Dataset.count).to eq(1)
      expect(@user.datasets.count).to eq(1)
      expect(@user.datasets.first.dataset_files.count).to eq(1)
    end

    it 'errors if a file does not match the schema' do

      @filename = 'invalid-schema.csv'
      @storage_key = "uploads/#{SecureRandom.uuid}/#{@filename}"

      path = File.join(Rails.root, 'spec', 'fixtures', @filename)
      allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(path))

      good_schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      stubbed_schema_url = url_with_stubbed_get_for(good_schema_path)

      file = {
        title: 'My File',
        description: 'My Description',
        file: Rack::Test::UploadedFile.new(path, "text/csv"),
        storage_key: @storage_key,
        schema_name: 'schema name',
        schema_description: 'schema description',
        schema: stubbed_schema_url
      }

      post '/api/datasets', params: {
        dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
        },
        file: file
      },
      headers: { 'Authorization' => "Token token=#{@user.api_key}" }

      expect(Dataset.count).to eq(0)
      expect(Error.count).to eq(1)
      expect(Error.first.messages).to eq([
        "Dataset files is invalid",
        "Your file 'My File' does not match the schema you provided"
      ])
    end
  end
end
