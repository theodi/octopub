require 'rails_helper'
require 'support/odlifier_licence_mock'

describe DatasetsController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'odlifier licence mock'

  let(:filename) { 'valid-schema.csv' }
  let(:storage_key) { filename }
  let(:url_for_data_file) { url_with_stubbed_get_for_storage_key(storage_key, filename) }
  let(:good_schema_path) { get_fixture_schema_file('good-schema.json') }
  let(:new_filename) { 'valid-schema-2.csv' }
  let(:new_storage_key) { new_filename }
  let(:new_url_for_data_file) { url_with_stubbed_get_for_storage_key(new_storage_key, new_filename) }
  let(:not_matching_filename) { 'invalid-schema.csv' }
  let(:not_matching_storage_key) { not_matching_filename }
  let(:url_for_not_matching_data_file) { url_with_stubbed_get_for_storage_key(not_matching_storage_key, not_matching_storage_key) }
  let(:schema_path) { get_fixture_schema_file('good-schema.json') }

  before(:each) do
    Sidekiq::Testing.inline!
    @user = create(:user)
    allow_any_instance_of(JekyllService).to receive(:create_data_files) { nil }
    allow_any_instance_of(JekyllService).to receive(:create_jekyll_files) { nil }
    allow_any_instance_of(CreateRepository).to receive(:perform)
  end

  before(:each, schema: true) do
    stub_request(:get, /schema\.json/).to_return(body: File.read(File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')))
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  describe 'update' do

    before(:each) do
      sign_in @user

      @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
        create(:dataset_file, filename: filename, storage_key: storage_key)
      ])


      @dataset_file = @dataset.dataset_files.first

      @dataset_hash = {
        description: "New description",
        publisher_name: "New Publisher",
        publisher_url: "http://new.publisher.com",
        license: "OGL-UK-3.0",
        frequency: "annual"
      }
    end

    context('successful update') do
      before(:each) do
        @repo = double(GitData)
        @dataset_filename = 'valid-schema.csv'
        @path = File.join(Rails.root, 'spec', 'fixtures', @dataset_filename)

        allow(Dataset).to receive(:find).with(@dataset.id) { @dataset }
        allow(Dataset).to receive(:find).with(@dataset.id.to_s) { @dataset }
        expect(RepoService).to receive(:fetch_repo).at_least(:once) { @repo }

        Dataset.set_callback(:update, :after, :update_dataset_in_github)
      end

      context('with schema', :schema) do

        before(:each) do
          schema = url_with_stubbed_get_for(good_schema_path)
          @dataset_file_schema = DatasetFileSchemaService.new('schema-name', 'schema-name-description', schema, @user).create_dataset_file_schema
          @dataset_file = @dataset.dataset_files.first
          @dataset_file.update(dataset_file_schema: @dataset_file_schema)
        end

        context 'with schema-compliant csv' do

          it 'updates a file in Github' do
            expect(@dataset_file.dataset_file_schema).to eq @dataset_file_schema
            expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github)

            put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [{
                id: @dataset_file.id,
                file: new_url_for_data_file
            }]}

            @dataset.reload
            expect(@dataset.dataset_files.first.dataset_file_schema).to eq @dataset_file_schema
          end

          context 'adds a new file in Github' do

            before :each do
              @dataset_file.file = nil
              @new_file = url_with_stubbed_get_for(@path)

              expect_any_instance_of(JekyllService).to receive(:add_to_github)
              expect_any_instance_of(JekyllService).to receive(:add_jekyll_to_github)
              expect_any_instance_of(JekyllService).to receive(:push_to_github)
              expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github)
            end

            it 'via a browser' do
              put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
                {
                  id: @dataset_file.id,
                  title: "New title",
                  description: "New description"
                 },
                {
                  title: "New file",
                  description: "New file description",
                  file: @new_file
                }
              ]}

              expect(@dataset.dataset_files.count).to eq(2)
            end

            it 'via a browser - original file has one schema, new file does not match it' do
              @dataset_filename = 'invalid-schema.csv'
              @path = File.join(Rails.root, 'spec', 'fixtures', @dataset_filename)
              @new_file = url_with_stubbed_get_for(@path)

              put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
                {
                  id: @dataset_file.id,
                  title: "New title",
                  description: "New description"
                 },
                {
                  title: "New file",
                  description: "New file description",
                  file: @new_file
                }
              ]}
              expect(@dataset.dataset_files.first.dataset_file_schema).to eq @dataset_file_schema
              expect(@dataset.dataset_files.second.dataset_file_schema).to be_nil
              expect(@dataset.dataset_files.count).to eq(2)
            end

            it 'via a browser - original file has one schema, new file has a different one' do
              @dataset_filename = 'valid-file-for-good-schema-2.csv'
              @path = File.join(Rails.root, 'spec', 'fixtures', @dataset_filename)
              @new_file = url_with_stubbed_get_for(@path)
              new_schema_path = get_fixture_schema_file('good-schema-2.json')
              new_schema = url_with_stubbed_get_for(new_schema_path)
              new_dataset_file_schema = DatasetFileSchemaService.new('new-schema-name', 'new-schema-name-description', new_schema, @user).create_dataset_file_schema
              expect(@dataset.dataset_files.first.dataset_file_schema).to eq @dataset_file_schema

              file_1_hash = {
                id: @dataset_file.id,
                title: "Old file New title",
                description: "Old file New description",
                dataset_file_schema_id: @dataset_file_schema.id
              }

              file_2_hash = {
                title: "New file",
                description: "New file description",
                file: @new_file,
                dataset_file_schema_id: new_dataset_file_schema.id
                }

              put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
                file_1_hash, file_2_hash
              ]}

              @dataset.reload

              expect(@dataset.dataset_files.first).to eq @dataset_file
              expect(@dataset.dataset_files.second.title).to eq 'New file'
              expect(@dataset.dataset_files.first.dataset_file_schema).to eq @dataset_file_schema
              expect(@dataset.dataset_files.second.dataset_file_schema).to eq new_dataset_file_schema
              expect(@dataset.dataset_files.count).to eq(2)
            end
          end
        end
      end

      context('without schema', schema: false) do

        it 'updates a dataset' do
          @dataset_file.file = nil
          expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github)

          put :update, params: { id: @dataset.id.to_s, dataset: @dataset_hash, files: [{
            id: @dataset_file.id,
            description: "New description"
          }]}

          expect(response).to redirect_to(edited_datasets_path)

          expect(@dataset.name).to eq("Dataset")
          expect(@dataset.description).to eq("New description")
          expect(@dataset.publisher_name).to eq("New Publisher")
          expect(@dataset.publisher_url).to eq("http://new.publisher.com")
          expect(@dataset.license).to eq("OGL-UK-3.0")
          expect(@dataset.frequency).to eq("annual")
          expect(@dataset.dataset_files.count).to eq(1)
          expect(@dataset.dataset_files.first.description).to eq("New description")
        end

        it 'returns 202 when async is set to true' do
          @dataset_file.file = nil
          expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github)

          put :update, params: { id: @dataset.id.to_s, dataset: @dataset_hash, files: [{
            id: @dataset_file.id,
            description: "New description"
          }], async: true }

          expect(response.code).to eq("202")
        end

        it 'updates a file in Github' do

          expect_any_instance_of(JekyllService).to receive(:update_in_github)
          expect_any_instance_of(JekyllService).to receive(:update_jekyll_in_github)
          expect_any_instance_of(JekyllService).to receive(:update_file_in_repo).with("datapackage.json", instance_of(String))
          expect_any_instance_of(JekyllService).to receive(:update_file_in_repo).with("_config.yml", instance_of(String))
          expect_any_instance_of(JekyllService).to receive(:push_to_github)

          put :update,  params: { id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @dataset_file.id,
              file: new_url_for_data_file
          }]}
        end

        it 'adds a new file in Github' do
          @dataset_file.file = nil

          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = url_with_stubbed_get_for(path)

          new_file = build(:dataset_file, dataset: @dataset, file: nil, filename: filename)

          expect(DatasetFile).to receive(:create) { new_file }
          expect_any_instance_of(JekyllService).to receive(:add_to_github)
          expect_any_instance_of(JekyllService).to receive(:add_jekyll_to_github)
          allow_any_instance_of(JekyllService).to receive(:push_to_github)
          expect_any_instance_of(JekyllService).to receive(:update_config_yml)
          expect_any_instance_of(JekyllService).to receive(:update_datapackage)

          put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
            {
              id: @dataset_file.id,
              title: "New title",
              description: "New description"
             },
            {
              title: "New file",
              description: "New file description",
              file: file
            }
          ]}

          expect(@dataset.dataset_files.count).to eq(2)
        end
      end
    end

    context 'unsuccessful update' do
      context 'with non-compliant csv', :schema do

        before(:each) do
          @repo = double(GitData)
          @url_for_schema = url_for_schema_with_stubbed_get_for(good_schema_path)
          @new_dataset_file_schema = DatasetFileSchemaService.new('new-schema-name', 'new-schema-name-description', @url_for_schema, @user).create_dataset_file_schema

          expect(RepoService).to receive(:fetch_repo) { @repo }
        end

        it 'does not update a file in Github' do
          @dataset_file.file = nil

          expect_any_instance_of(JekyllService).to_not receive(:update_dataset_in_github)

          put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @dataset_file.id,
              file: url_for_not_matching_data_file,
              dataset_file_schema_id: @new_dataset_file_schema.id
          }]}

          expect(Error.count).to eq(1)
          expect(Error.first.messages).to eq([
            "Dataset files is invalid",
            "Your file '#{@dataset_file.title}' does not match the schema you provided"
          ])
        end
      end
    end

    it 'filters out empty file params' do

      files = [
        {
          id: @dataset_file.id,
          title: "New title",
          description: "New description"
        },
        {
          title: "New file",
          description: "New file description",
          file: "http://example.com/new-file.csv",
          storage_key: 'new-file.csv'
        },
        {
          title: "This should get binned"
        }
      ]

      expect(UpdateDataset).to receive(:perform_async).with(@dataset.id.to_s, @dataset_hash.stringify_keys!, [
          {
            "id" => @dataset_file.id.to_s,
            "title" => "New title",
            "description" => "New description"
          },
          {
            "title" => "New file",
            "description" => "New file description",
            "file" => "http://example.com/new-file.csv",
            "storage_key" => "new-file.csv"
          }
        ], channel_id: nil
      ) { build(:dataset) }

      put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: files }
    end
  end

  describe 'updating a github private dataset' do

    before(:each) do
      sign_in @user

      @dataset = create(:dataset, :with_callback,  name: "Dataset", publishing_method: :github_private, user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])

    end

    after(:each) do
      skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)
    end

    it 'can update private flag' do
      @repo = double(GitData)
      expect(RepoService).to receive(:fetch_repo).with(@dataset).twice { @repo }
      expect_any_instance_of(JekyllService).to receive(:create_public_views)
      expect_any_instance_of(JekyllService).to receive(:update_dataset_in_github)
      expect_any_instance_of(RepoService).to receive(:make_public)
      put :update, params: { id: @dataset.id, dataset: { publishing_method: :github_public }}
      @dataset.reload

      expect(@dataset.restricted).to be false
    end

    it 'can add a file' do
      @dataset.update_columns(publishing_method: :local_private)
      @dataset_file = @dataset.dataset_files.first
      @dataset_file.file = nil

      filename = 'test-data.csv'
      path = File.join(Rails.root, 'spec', 'fixtures', filename)
      file = url_with_stubbed_get_for(path)

      new_file = build(:dataset_file, dataset: @dataset, file: nil)

      expect(DatasetFile).to receive(:create) { new_file }
      expect_any_instance_of(JekyllService).to_not receive(:add_to_github)
      expect_any_instance_of(JekyllService).to_not receive(:add_jekyll_to_github)
      expect_any_instance_of(JekyllService).to_not receive(:push_to_github)
      expect_any_instance_of(JekyllService).to_not receive(:update_datapackage)

      put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
        {
          id: @dataset_file.id,
          title: "New title",
          description: "New description"
         },
        {
          title: "New file",
          description: "New file description",
          file: file
        }
      ]}

      expect(@dataset.dataset_files.count).to eq(2)
    end
  end

  describe 'updating a local private dataset' do

    before(:each) do
      sign_in @user
      @dataset = create(:dataset, :with_callback,  name: "Dataset", publishing_method: :local_private, user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])
      github_user = OpenStruct.new(avatar_url: "http://www.example.org/avatar2.png")
      allow_any_instance_of(User).to receive(:github_user) { github_user }
      repo = double(GitData)
      allow_any_instance_of(Dataset).to receive(:owner_avatar) { "http://example.org/avatar.png" }
      expect(repo).to receive(:html_url) { 'https://example.org' }
      expect(repo).to receive(:name) { 'examplename'}
      expect(repo).to receive(:full_name) { 'examplename' }
      expect(RepoService).to receive(:create_repo) { repo }
      expect(RepoService).to receive(:fetch_repo).at_least(:once) { repo }
      expect(RepoService).to receive(:prepare_repo).at_least(:once)
      expect_any_instance_of(JekyllService).to receive(:create_data_files) { nil }
      expect_any_instance_of(JekyllService).to receive(:push_to_github) { nil }
      expect_any_instance_of(Dataset).to receive(:publish_public_views) { nil }
      # expect_any_instance_of(Dataset).to receive(:send_success_email) { nil }

      allow_any_instance_of(CreateRepository).to receive(:perform).and_call_original
      Sidekiq::Testing.inline!
    end

    after(:each) do
      skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)
      Sidekiq::Testing.fake!
    end

    it 'create a new public repo' do
      put :update, params: { id: @dataset.id, dataset: { publishing_method: :github_public }}
      @dataset.reload

      expect(@dataset.github_public?).to be true
    end
  end
end
