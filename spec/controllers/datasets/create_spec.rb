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

        @repo = double(GitData)

        expect(@repo).to receive(:html_url) { nil }
        expect(@repo).to receive(:name) { nil }
        expect(@repo).to receive(:full_name) { nil }
        expect(@repo).to receive(:save)
      end

      it 'creates a dataset with one file' do
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

      it 'creates a dataset in an organization' do
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

      it 'returns 202 when async is set to true' do
        expect(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
        }, files: @files, async: true

        expect(response.code).to eq("202")
      end

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

      it 'handles non-url files' do

        path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')

        expect(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }
        allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(path))

        @files.first["file"] = fixture_file_upload('test-data.csv')

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

  end
end
