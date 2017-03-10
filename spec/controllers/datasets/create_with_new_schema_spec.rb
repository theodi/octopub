require 'rails_helper'

describe DatasetsController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do

  let(:dataset_name) { "My cool dataset" }
  let(:description) { "This is a description" }
  let(:publisher_name) { "Cool inc"}
  let(:publisher_url) { "http://example.com"}
  let(:license) { "OGL-UK-3.0" }
  let(:frequency) { "Monthly" }
  let(:filename) { 'valid-schema.csv' }
  let(:storage_key) { filename }
  let(:url_for_data_file) { url_with_stubbed_get_for_storage_key(storage_key, filename) }
  let(:not_matching_filename) { 'invalid-schema.csv' }
  let(:not_matching_storage_key) { not_matching_filename }
  let(:url_for_not_matching_data_file) { url_with_stubbed_get_for_storage_key(not_matching_storage_key, not_matching_storage_key) }
  let(:schema_path) { get_fixture_schema_file('good-schema.json') }

  before(:each) do
    Sidekiq::Testing.inline!
    skip_dataset_callbacks!

    @user = create(:user)
    sign_in @user
    allow_any_instance_of(JekyllService).to receive(:create_data_files) { nil }
    allow_any_instance_of(JekyllService).to receive(:create_jekyll_files) { nil }

    @url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)
    @files ||= []
  end

  after(:each) do
    Sidekiq::Testing.fake!
    set_dataset_callbacks!
  end

  describe 'create dataset with a new schema' do
    context 'returns an error if the file does not match the schema' do

      before(:each) do
        @files << {
          title: 'My File',
          description: 'My Description',
          file: url_for_not_matching_data_file,
          storage_key: not_matching_storage_key,
          schema_name: 'schema name',
          schema_description: 'schema description',
          schema: @url_for_schema
        }

        @dataset = {
          name: dataset_name,
          description: description,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          license: license,
          frequency: frequency
        }
      end

      it 'without websockets' do

        post :create, params: { dataset: @dataset, files: @files }

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
        post :create, params: { dataset: @dataset, files: @files, channel_id: 'foo-bar' }
      end
    end

    it 'creates sucessfully if the file matches the schema' do

      @files << {
        title: 'My File',
        description: 'My Description',
        file: url_for_data_file,
        storage_key: storage_key,
        schema_name: 'schem nme',
        schema_description: 'schema description',
        schema: @url_for_schema
      }

      request = post :create, params: { dataset: {
        name: dataset_name,
        description: description,
        publisher_name: publisher_name,
        publisher_url: publisher_url,
        license: license,
        frequency: frequency
      }, files: @files }

      expect(request).to redirect_to(created_datasets_path)
      expect(Dataset.count).to eq(1)
      expect(DatasetFileSchema.count).to eq(1)

      expect(@user.dataset_file_schemas.count).to eq(1)
      expect(@user.datasets.count).to eq(1)
      expect(@user.datasets.first.dataset_files.count).to eq(1)

      expect(@user.datasets.first.dataset_files.first.dataset_file_schema.url).to eq(@url_for_schema)
    end
  end
end
