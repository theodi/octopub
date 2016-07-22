require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    Sidekiq::Testing.inline!
    skip_dataset_callbacks!

    @user = create(:user, name: "User McUser", email: "user@user.com")
    sign_in @user

    @name = "My cool dataset"
    @description = "This is a description"
    @publisher_name = "Cool inc"
    @publisher_url = "http://example.com"
    @license = "OGL-UK-3.0"
    @frequency = "Monthly"
    @files ||= []

    allow_any_instance_of(DatasetFile).to receive(:add_to_github) { nil }
    allow_any_instance_of(Dataset).to receive(:create_files) { nil }
  end

  after(:each) do
    Sidekiq::Testing.fake!
    set_dataset_callbacks!
  end

  describe 'create dataset' do

    it 'returns an error if there are no files specified' do
      request = post 'create', dataset: {
        name: @name,
        description: @description,
        publisher_name: @publisher_name,
        publisher_url: @publisher_url,
        license: @license,
        frequency: @frequency
      }, files: []

      expect(request).to render_template(:new)
      expect(flash[:notice]).to eq("You must specify at least one dataset")
    end

    context 'with one file' do

      before(:each) do
        name = 'Test Data'
        description = Faker::Company.bs
        filename = 'test-data.csv'
        path = File.join(Rails.root, 'spec', 'fixtures', filename)

        Dataset.set_callback(:create, :after, :create_in_github)

        @files << {
          :title => name,
          :description => description,
          :file => fake_file(path)
        }
      end

      before(:each, async: false) do
        @repo = double(GitData)

        expect(@repo).to receive(:html_url) { nil }
        expect(@repo).to receive(:name) { nil }
        expect(@repo).to receive(:full_name) { nil }
        expect(@repo).to receive(:save)
      end

      it 'creates a dataset with one file', async: false do
        expect(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        request = post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency
        }, files: @files

        expect(request).to redirect_to(created_datasets_path)
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end

      it 'creates a dataset in an organization', async: false do
        organization = 'my-cool-organization'

        expect(GitData).to receive(:create).with(organization, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        request = post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
          owner: organization
        }, files: @files

        expect(request).to redirect_to(created_datasets_path)
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end

      # it 'queues a job when async is set to true', :async do
      #   expect {
      #     post 'create', dataset: {
      #       name: @name,
      #       description: @description,
      #       publisher_name: @publisher_name,
      #       publisher_url: @publisher_url,
      #       license: @license,
      #       frequency: @frequency,
      #     }, files: @files, async: true
      #   }.to change(Sidekiq::Extensions::DelayedClass.jobs, :size).by(1)
      #
      #   expect(response.code).to eq("202")
      # end

      it 'extracts from data params', async: false do
        # This is a special Zapier thing, it sends the data in a hash called 'data'
        expect(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        data = {
          dataset: {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency
          },
          files: [
            {
              title: @files[0][:title],
              description: @files[0][:description],
            }
          ]
        }.to_json

        request = post 'create', data: data,
          files: [
            {
              file: @files[0][:file]
            }
          ]

        expect(request).to redirect_to(created_datasets_path)
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end
    end

    context('with a schema') do

      before(:each) do
        schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')
        @schema = fake_file(schema_path)
      end

      context 'returns an error if the file does not match the schema' do

        before(:each) do
          path = File.join(Rails.root, 'spec', 'fixtures', 'invalid-schema.csv')
          schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')

          @files << {
            :title => 'My File',
            :description => 'My Description',
            :file => fake_file(path)
          }

          @dataset = {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency,
            schema: @schema
          }
        end

        it 'without websockets' do
          post 'create', dataset: @dataset, files: @files

          expect(Dataset.count).to eq(0)
          expect(Error.count).to eq(1)
          expect(Error.first.messages).to eq([
            "Dataset files is invalid",
            "Your file 'My File' does not match the schema you provided"
          ])
        end

        it 'with websockets' do
          mock_client = mock_pusher('foo-bar')

          expect(mock_client).to receive(:trigger).with('dataset_failed', [
            "Dataset files is invalid",
            "Your file 'My File' does not match the schema you provided"
          ])

          post 'create', dataset: @dataset, files: @files, channel_id: 'foo-bar'
        end

      end

      it 'creates sucessfully if the file matches the schema' do
        path = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')

        @files << {
          :title => 'My File',
          :description => 'My Description',
          :file => fake_file(path)
        }

        request = post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
          schema: @schema
        }, files: @files

        expect(request).to redirect_to(created_datasets_path)
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end

    end

    context 'via the API' do

      before(:each) do
        name = 'Test Data'
        description = Faker::Company.bs
        filename = 'test-data.csv'
        path = File.join(Rails.root, 'spec', 'fixtures', filename)

        Dataset.set_callback(:create, :after, :create_in_github)

        @repo = double(GitData)

        allow(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        @files << {
          :title => name,
          :description => description,
          :file => fake_file(path)
        }
      end

      it 'returns a job ID' do
        expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:name) { 'my-cool-repo' }
        expect(@repo).to receive(:full_name) { 'user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:save)

        post 'create', :format => :json, dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency
        },
        files: @files,
        api_key: @user.api_key

        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)

        expect(response.body).to match /"job_url":"http:\/\/test\.host\/jobs\//
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

          files = [{
            :title => 'My File',
            :description => 'My Description',
            :file => fake_file(path)
          }]

          post 'create', :format => :json, dataset: {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency,
            schema: @schema
          },
          files: files,
          api_key: @user.api_key

          expect(Dataset.count).to eq(1)
          expect(@user.datasets.count).to eq(1)
          expect(@user.datasets.first.dataset_files.count).to eq(1)
        end

        it 'errors is a file does not match the schema' do
          path = File.join(Rails.root, 'spec', 'fixtures', 'invalid-schema.csv')

          files = [{
            :title => 'My File',
            :description => 'My Description',
            :file => fake_file(path)
          }]

          post 'create', :format => :json, dataset: {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency,
            schema: @schema
          },
          files: files,
          api_key: @user.api_key

          expect(Dataset.count).to eq(0)
          expect(Error.count).to eq(1)
          expect(Error.first.messages).to eq([
            "Dataset files is invalid",
            "Your file 'My File' does not match the schema you provided"
          ])
        end

      end

      it 'skips the authenticity token if creating via the API' do
        expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:name) { 'my-cool-repo' }
        expect(@repo).to receive(:full_name) { 'user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:save)
        expect(controller).to_not receive(:verify_authenticity_token)

        post 'create', :format => :json, dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency
        },
        files: @files,
        api_key: @user.api_key
      end

    end

  end
end
