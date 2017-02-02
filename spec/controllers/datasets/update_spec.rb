require 'spec_helper'

describe DatasetsController, type: :controller do

  let(:data_file) { File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv') }
  let(:data_file_not_matching_schema) { File.join(Rails.root, 'spec', 'fixtures', 'invalid-schema.csv') }
  let(:good_schema_path) { File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json') }

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

      schema = url_with_stubbed_get_for(good_schema_path)

      @dataset_file = @dataset.dataset_files.first
      dataset_file_schema = DatasetFileSchemaService.new.create_dataset_file_schema('schema-name', 'schema-name-description', schema)

      @dataset_hash = {
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

            expect(@dataset_file).to receive(:update_in_github)
            expect(@dataset_file).to receive(:update_jekyll_in_github)

            put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [{
                id: @dataset_file.id,
                file: file
            }]}
          end

          context 'adds a new file in Github' do

            before :each do
              @dataset_file.file = nil

              @dataset_filename = 'valid-schema.csv'
              @path = File.join(Rails.root, 'spec', 'fixtures', @dataset_filename)
              @new_file = url_with_stubbed_get_for(@path)

              file = build(:dataset_file, dataset: @dataset, file: nil)

              expect(DatasetFile).to receive(:new_file) { file }
              expect(file).to receive(:add_to_github)
              expect(file).to receive(:add_jekyll_to_github)
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
          end
        end

      end

      context('without schema', schema: false) do

        it 'updates a dataset' do
          @dataset_file.file = nil

          put :update, params: { id: @dataset.id.to_s, dataset: @dataset_hash, files: [{
            id: @dataset_file.id,
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
          @dataset_file.file = nil

          put :update, params: { id: @dataset.id.to_s, dataset: @dataset_hash, files: [{
            id: @dataset_file.id,
            description: "New description"
          }], async: true }

          expect(response.code).to eq("202")
        end

        it 'updates a file in Github' do
          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = url_with_stubbed_get_for(path)

          expect(@dataset_file).to receive(:update_in_github)
          expect(@dataset_file).to receive(:update_jekyll_in_github)

          put :update,  params: { id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @dataset_file.id,
              file: file
          }]}
        end

        it 'adds a new file in Github' do
          @dataset_file.file = nil

          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = url_with_stubbed_get_for(path)

          new_file = build(:dataset_file, dataset: @dataset, file: nil)

          expect(DatasetFile).to receive(:new_file) { new_file }
          expect(new_file).to receive(:add_to_github)
          expect(new_file).to receive(:add_jekyll_to_github)

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

    context('unsuccessful update') do

      context 'with non-compliant csv', :schema do



        before(:each) do
          @repo = double(GitData)
          expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
          @url_for_schema = url_for_schema_with_stubbed_get_for(good_schema_path)
        end

        it 'does not update a file in Github' do
          @dataset_file.file = nil
          file = url_with_stubbed_get_for(data_file_not_matching_schema)

          expect(@dataset_file).to_not receive(:update_in_github)

          put :update, params: { id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @dataset_file.id,
              file: file,
              schema_name: 'schema name',
              schema_description: 'schema description',
              schema: @url_for_schema
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
          file: "http://example.com/new-file.csv"
        },
        {
          title: "This should get binned"
        }
      ]

      expect(UpdateDataset).to receive(:perform_async).with(@dataset.id.to_s, @user.id, @dataset_hash.stringify_keys!, [
          {
            "id" => @dataset_file.id.to_s,
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

  describe 'updating a restricted dataset' do

    before(:each) do
      sign_in @user
      @dataset = create(:dataset, name: "Dataset", restricted: true, user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])
      @dataset.save
      @repo = double(GitData)
      expect(Dataset).to receive(:find).with(@dataset.id.to_s) { @dataset }
      expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
    end

    it 'can update private flag' do
      expect(@repo).to receive(:make_public)
      put :update, params: { id: @dataset.id, dataset: {restricted: true}}
      @dataset.reload
      expect(@dataset.private).to be_true
    end
  
  end

end
