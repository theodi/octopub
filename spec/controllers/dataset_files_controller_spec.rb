require 'rails_helper'

describe DatasetFilesController, type: :controller do

  let(:filename) { 'test-data.csv' }
  let(:storage_key) { filename }
  let(:string_io_for_data_file) { get_string_io_from_fixture_file(filename) }
  let(:publisher) { create(:user) }
  let(:random_publisher) { create(:user) }
  let(:admin) { create(:user, role: :admin) }

  before(:each) do
    sign_in publisher
    @dataset_file = create(:dataset_file, filename: filename, file: string_io_for_data_file, storage_key: storage_key)
    @dataset = create(:dataset, user: publisher, dataset_files: [ @dataset_file ])
  end

  after(:each) do
    sign_out
  end

  context 'viewing your data' do
    before(:each) do
      sign_in publisher
    end

    describe 'index' do
      it "returns http success" do
        get :index, params: { dataset_id: @dataset.id }
        expect(response).to be_success
      end
    end

    it 'index with schema' do
      schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json')
      data_file = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')
      url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)

      dataset_file_schema = DatasetFileSchemaService.create(
        name: 'schema-name', 
        description: 'schema-name-description', 
        url_in_s3: url_for_schema, 
        user: publisher
      )
      @dataset_file.update(dataset_file_schema: dataset_file_schema)

      get :index, params: { dataset_id: @dataset.id }
      expect(response).to be_success
    end
  end

  describe 'you cannot see other user data' do
    it 'if they have a private local repo' do
      sign_in random_publisher
      get :index, params: { dataset_id: @dataset.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'unless you are an administrator' do
      sign_in admin
      get :index, params: { dataset_id: @dataset.id }
      expect(response).to be_success
    end
  end
end
