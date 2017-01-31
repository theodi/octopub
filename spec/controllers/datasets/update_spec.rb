require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    Sidekiq::Testing.inline!

    @user = create(:user, name: "User McUser", email: "user@user.com")
    skip_callback_if_exists(Dataset, :create, :after, :create_repo_and_populate)

    allow_any_instance_of(Dataset).to receive(:create_data_files) { nil }
    allow_any_instance_of(Dataset).to receive(:create_jekyll_files) { nil }
  end

  before(:each, schema: true) do
    stub_request(:get, /schema\.json/).to_return(body: File.read(File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')))
  end

  after(:each) do
    Sidekiq::Testing.fake!

    Dataset.set_callback(:create, :after, :create_repo_and_populate)
  end

  describe 'update' do

    before(:each) do
      sign_in @user
      @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])

      good_schema = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      schema = url_with_stubbed_get_for(good_schema)
      @dataset_file_schema = DatasetSchemaService.new.create_dataset_file_schema(schema)

      @dataset.save
      @file = @dataset.dataset_files.first

      @dataset_hash = {
      #  name: "New name",
        description: "New description",
        publisher_name: "New Publisher",
        publisher_url: "http://new.publisher.com",
        license: "OGL-UK-3",
        frequency: "annual"
      }
    end

    context('successful update') do
      before(:each) do
        @repo = double(GitData)

        expect(Dataset).to receive(:find).with(@dataset.id.to_s) { @dataset }
        expect(@dataset).to receive(:update_datapackage)
        expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
        expect(@repo).to receive(:save)
        Dataset.set_callback(:update, :after, :update_in_github)
      end

      context('with schema', :schema) do
        context 'with schema-compliant csv' do

          it 'updates a file in Github' do
            filename = 'valid-schema.csv'
            path = File.join(Rails.root, 'spec', 'fixtures', filename)
            file = url_with_stubbed_get_for(path)

            expect(@file).to receive(:update_in_github)
            expect(@file).to receive(:update_jekyll_in_github)

            put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [{
                id: @file.id,
                file: file
            }]}
          end

          context 'adds a new file in Github' do

            before :each do
              @file.file = nil

              @filename = 'valid-schema.csv'
              @path = File.join(Rails.root, 'spec', 'fixtures', @filename)
              @new_file = url_with_stubbed_get_for(@path)

              file = build(:dataset_file, dataset: @dataset, file: nil)

              expect(DatasetFile).to receive(:new_file) { file }
              expect(file).to receive(:add_to_github)
              expect(file).to receive(:add_jekyll_to_github)
            end

            it 'via a browser' do
              put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
                {
                  id: @file.id,
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
          end
        end

      end

      context('without schema', schema: false) do

        it 'updates a dataset' do
          @file.file = nil

          put :update, params: { id: @dataset.id.to_s, dataset: @dataset_hash, files: [{
            id: @file.id,
            description: "New description"
          }]}

          expect(response).to redirect_to(edited_datasets_path)

          expect(@dataset.name).to eq("Dataset")
          expect(@dataset.description).to eq("New description")
          expect(@dataset.publisher_name).to eq("New Publisher")
          expect(@dataset.publisher_url).to eq("http://new.publisher.com")
          expect(@dataset.license).to eq("OGL-UK-3")
          expect(@dataset.frequency).to eq("annual")
          expect(@dataset.dataset_files.count).to eq(1)
          expect(@dataset.dataset_files.first.description).to eq("New description")
        end

        it 'returns 202 when async is set to true' do
          @file.file = nil

          put :update, params: { id: @dataset.id.to_s, dataset: @dataset_hash, files: [{
            id: @file.id,
            description: "New description"
          }], async: true }

          expect(response.code).to eq("202")
        end

        it 'updates a file in Github' do
          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = url_with_stubbed_get_for(path)

          expect(@file).to receive(:update_in_github)
          expect(@file).to receive(:update_jekyll_in_github)

          put :update,  params: { id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @file.id,
              file: file
          }]}
        end

        it 'adds a new file in Github' do
          @file.file = nil

          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = url_with_stubbed_get_for(path)

          new_file = build(:dataset_file, dataset: @dataset, file: nil)

          expect(DatasetFile).to receive(:new_file) { new_file }
          expect(new_file).to receive(:add_to_github)
          expect(new_file).to receive(:add_jekyll_to_github)

          put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
            {
              id: @file.id,
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

    context('unsuccessful update') do

      context 'with non-compliant csv', :schema do
        before(:each) do
          @repo = double(GitData)
          expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
 #         @dataset.update(dataset_file_schema: @dataset_file_schema)
        end

        it 'does not update a file in Github' do
          @file.file = nil
          filename = 'invalid-schema.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = url_with_stubbed_get_for(path)

          expect(@file).to_not receive(:update_in_github)

          put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @file.id,
              file: file
          }]}

          expect(Error.count).to eq(1)
          expect(Error.first.messages).to eq([
            "Dataset files is invalid",
            "Your file '#{@file.title}' does not match the schema you provided"
          ])
        end

        context 'does not add new file in Github' do
          before :each do
            @file.file = nil

            @filename = 'invalid-schema.csv'
            @path = File.join(Rails.root, 'spec', 'fixtures', @filename)
            @new_file = url_with_stubbed_get_for(@path)

            file = build(:dataset_file, dataset: @dataset, file: nil)

            expect(file).to_not receive(:add_to_github)
          end

          it 'without websockets' do

            put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
              {
                id: @file.id,
                title: "New title",
                description: "New description"
               },
              {
                title: "New file",
                description: "New file description",
                file: @new_file
              }
            ]}

            expect(@dataset.dataset_files.count).to eq(1)
            expect(Error.count).to eq(1)
            expect(Error.first.messages).to eq([
              "Dataset files is invalid",
              "Your file 'New file' does not match the schema you provided"
            ])
          end

          it 'with websockets' do
            mock_client = mock_pusher('foo-bar')

            expect(mock_client).to receive(:trigger).with('dataset_failed', [
              "Dataset files is invalid",
              "Your file 'New file' does not match the schema you provided"
            ])

            put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [
              {
                id: @file.id,
                title: "New title",
                description: "New description"
               },
              {
                title: "New file",
                description: "New file description",
                file: @new_file
              }
            ], channel_id: 'foo-bar' }
          end
        end
      end

    end

    it 'filters out empty file params' do

      files = [
        {
          id: @file.id,
          title: "New title",
          description: "New description"
        },
        {
          title: "New file",
          description: "New file description",
          file: "http://example.com/new-file.csv"
        },
        {
          title: "This should get binned"
        }
      ]

      expect(UpdateDataset).to receive(:perform_async).with(@dataset.id.to_s, @user.id, @dataset_hash.stringify_keys!, [
          {
            "id" => @file.id.to_s,
            "title" => "New title",
            "description" => "New description"
          },
          {
            "title" => "New file",
            "description" => "New file description",
            "file" => "http://example.com/new-file.csv"
          }
        ], channel_id: nil
      ) { build(:dataset) }

      put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: files }
    end

  end

end
