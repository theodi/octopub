require 'rails_helper'
require 'support/odlifier_licence_mock'

describe DatasetsController, type: :controller do
  include_context 'odlifier licence mock'

  let(:dataset_name) { "My cool dataset" }
  let(:description) { "This is a description" }
  let(:publisher_name) { "Cool inc"}
  let(:publisher_url) { "http://example.com"}
  let(:license) { "OGL-UK-3.0" }
  let(:frequency) { "Monthly" }

  before(:each) do
    Sidekiq::Testing.inline!

    @user = create(:user)
    sign_in @user

    @name = "My cool dataset"
    @description = "This is a description"
    @publisher_name = "Cool inc"
    @publisher_url = "http://example.com"
    @license = "OGL-UK-3.0"
    @frequency = "Monthly"
    @files ||= []

    @repo = double(GitData)

    allow(GitData).to receive(:create).with(@user.github_username, @name, restricted: false, client: a_kind_of(Octokit::Client)) {
      @repo
    }
    allow(GitData).to receive(:find).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
      @repo
    }
    allow(RepoService).to receive(:prepare_repo)
    allow_any_instance_of(User).to receive(:github_user) {
      OpenStruct.new(
        avatar_url: "http://www.example.org/avatar2.png"
      )
    }

    allow_any_instance_of(Dataset).to receive(:complete_publishing)
    allow_any_instance_of(JekyllService).to receive(:create_data_files) { nil }
    allow_any_instance_of(JekyllService).to receive(:create_jekyll_files) { nil }

    allow(controller).to receive(:current_user) { @user }
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  describe 'do not create dataset' do
    context 'with missing things' do
      before(:each) do
        name = 'Test Data'
        description = Faker::Company.bs
        filename = 'test-data.csv'
        # filename = 'white space.csv'
        path = File.join(Rails.root, 'spec', 'fixtures', filename)

        @files << {
          :title => name,
          :description => description,
          :file => url_with_stubbed_get_for(path)
        }

      end

      it 'returns an error if no publisher is specified' do

        request = post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency
        }, files: @files }

        expect(request).to render_template(:new)
        expect(flash[:no_publisher]).to eq("Please include the name of the publisher")
      end

      it 'returns an error if there are no files specified' do
        request = post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency
        }, files: [] }

        expect(request).to render_template(:new)
        expect(flash[:no_files]).to eq("You must specify at least one dataset")
      end

      it 'returns an error if there are no files nor pubslisher specified' do
        request = post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency
        }, files: [] }

        expect(request).to render_template(:new)
        expect(flash[:no_files]).to eq("You must specify at least one dataset")
        expect(flash[:no_publisher]).to eq("Please include the name of the publisher")
      end
    end

  end

  describe 'create dataset' do
    context 'with one file' do

      before(:each) do
        name = 'Test Data'
        description = Faker::Company.bs
        # filename = 'test-data.csv'
        filename = 'white space.csv'
        path = File.join(Rails.root, 'spec', 'fixtures', filename)
        @storage_key = "uploads/#{SecureRandom.uuid}/#{filename}"

        @files << {
          :title => name,
          :description => description,
          :file => url_with_stubbed_get_for_storage_key(@storage_key, filename),
          :storage_key => @storage_key
        }

        @repo = double(GitData)

        expect(@repo).to receive(:html_url) { nil }
        expect(@repo).to receive(:name) { nil }
        expect(@repo).to receive(:full_name) { nil }
        expect(@repo).to receive(:save)
      end

      def creation_assertions(publishing_method = :github_public)
        expect(request).to redirect_to(created_datasets_path(publishing_method: publishing_method))
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        the_dataset = @user.datasets.first
        expect(the_dataset.dataset_files.count).to eq(1)
        expect(the_dataset.dataset_files.first.storage_key).to_not be_nil
      end

      it 'creates a dataset with one file' do
        expect(GitData).to receive(:create).with(@user.github_username, @name, restricted: false, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        request = post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency,
          publishing_method: :github_public,
          owner: controller.send(:current_user).github_username
        }, files: @files }

        creation_assertions
        expect(@user.datasets.first.owner).to eq @user.github_username
      end

      it 'creates a restricted dataset' do
        expect(GitData).to receive(:create).with(@user.github_username, @name, restricted: true, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        request = post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency,
          publishing_method: :github_private,
        }, files: @files }

        creation_assertions(:github_private)
        expect(@user.datasets.first.publishing_method).to eq 'github_private'
      end

      it 'creates a dataset in an organization' do
        organization = 'my-cool-organization'

        expect(GitData).to receive(:create).with(organization, @name, restricted: false, client: a_kind_of(Octokit::Client)) {
          @repo
        }
        expect(GitData).to receive(:find).twice.with(organization, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        request = post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency,
          publishing_method: :github_public,
          owner: organization
        }, files: @files }

        creation_assertions
        expect(@user.datasets.first.owner).to eq organization
      end

      it 'returns 202 when async is set to true' do
        expect(GitData).to receive(:create).with(@user.github_username, @name, restricted: false, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency,
          publishing_method: :github_public,
        }, files: @files, async: true }

        expect(response.code).to eq("202")
      end

      it 'extracts from data params', async: false do
        # This is a special Zapier thing, it sends the data in a hash called 'data'
        expect(GitData).to receive(:create).with(@user.github_username, @name, restricted: false, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        data = {
          dataset: {
            name: dataset_name,
            description: description,
            publisher_name: publisher_name,
            publisher_url: publisher_url,
            license: license,
            publishing_method: :github_public,
            frequency: frequency
          },
          files: [
            {
              title: @files[0][:title],
              description: @files[0][:description],
            }
          ]
        }.to_json

        request = post :create, params: { data: data,
          files: [
            {
              file: @files[0][:file]
            }
          ]}

        creation_assertions
      end

      it 'handles non-url files' do

        filename = 'test-data.csv'
        path = File.join(Rails.root, 'spec', 'fixtures', filename)

        expect(GitData).to receive(:create).with(@user.github_username, @name, restricted: false, client: a_kind_of(Octokit::Client)) {
          @repo
        }
        allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(path))

        @files.first["file"] = fixture_file_upload(filename)
        @files.first["storage_key"] = filename

        request = post :create, params: { dataset: {
          name: dataset_name,
          description: description,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          license: license,
          publishing_method: :github_public,
          frequency: frequency
        }, files: @files }

        creation_assertions
      end
    end
  end
end
