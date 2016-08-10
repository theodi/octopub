require 'spec_helper'

describe 'POST /datasets' do

    before(:each) do
      Sidekiq::Testing.inline!
      skip_dataset_callbacks!

      @user = create(:user, name: "User McUser", email: "user@user.com")

      @name = "My cool dataset"
      @description = "This is a description"
      @publisher_name = "Cool inc"
      @publisher_url = "http://example.com"
      @license = "OGL-UK-3.0"
      @frequency = "Monthly"

      allow_any_instance_of(DatasetFile).to receive(:add_to_github) { nil }
      allow_any_instance_of(Dataset).to receive(:create_files) { nil }

      name = 'Test Data'
      description = Faker::Company.bs
      filename = 'test-data.csv'
      path = File.join(Rails.root, 'spec', 'fixtures', filename)

      Dataset.set_callback(:create, :after, :create_in_github)

      @repo = double(GitData)

      allow(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
        @repo
      }

      @file = {
        :title => name,
        :description => description,
        :file => fixture_file_upload(path)
      }
    end

    after(:each) do
      Sidekiq::Testing.fake!
    end

    it 'returns a job ID' do
      expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
      expect(@repo).to receive(:name) { 'my-cool-repo' }
      expect(@repo).to receive(:full_name) { 'user-mc-user/my-cool-repo' }
      expect(@repo).to receive(:save)

      post '/api/datasets', {
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
      {
        'Authorization' => "Token token=#{@user.api_key}"
      }

      expect(Dataset.count).to eq(1)
      expect(@user.datasets.count).to eq(1)
      expect(@user.datasets.first.dataset_files.count).to eq(1)

      json = JSON.parse(response.body)

      expect(json['job_url']).to match /\/api\/jobs\/(.+)\.json/
    end

    it 'errors with an invalid license' do
      post '/api/datasets', {
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
      {
        'Authorization' => "Token token=#{@user.api_key}"
      }

      expect(response.code).to eq("400")

      json = JSON.parse(response.body)

      expect(json['error']).to eq('dataset[license] does not have a valid value')
    end

    context('with a schema') do

      before(:each) do
        schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')
        @schema = fake_file(schema_path)
      end

      it 'creates a dataset sucessfully' do
        expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:name) { 'my-cool-repo' }
        expect(@repo).to receive(:full_name) { 'user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:save)

        path = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')

        file = {
          :title => 'My File',
          :description => 'My Description',
          :file => fixture_file_upload(path)
        }

        post '/api/datasets', {
          dataset: {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency,
            schema: @schema
          },
          file: file
        },
        {
          'Authorization' => "Token token=#{@user.api_key}"
        }

        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end

      it 'errors if a file does not match the schema' do
        path = File.join(Rails.root, 'spec', 'fixtures', 'invalid-schema.csv')

        file = {
          :title => 'My File',
          :description => 'My Description',
          :file => fixture_file_upload(path)
        }

        post '/api/datasets', {
          dataset: {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency,
            schema: @schema
          },
          file: file
        },
        {
          'Authorization' => "Token token=#{@user.api_key}"
        }

        expect(Dataset.count).to eq(0)
        expect(Error.count).to eq(1)
        expect(Error.first.messages).to eq([
          "Dataset files is invalid",
          "Your file 'My File' does not match the schema you provided"
        ])
      end

    end
end
