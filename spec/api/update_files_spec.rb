require 'rails_helper'
require 'support/odlifier_licence_mock'

describe 'PUT /datasets/:id/files/:file_id', vcr: { :match_requests_on => [:host, :method] } do
  include_context 'odlifier licence mock'

  before(:each) do
    Sidekiq::Testing.inline!
    allow_any_instance_of(CreateRepository).to receive(:perform)
    skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)

    @user = create(:user)
    @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
      create(:dataset_file, title: "Test Data")
    ])

    @file = @dataset.dataset_files.last
    args = {}
    @repo = double(GitData)

    allow(RepoService).to receive(:fetch_repo) { @repo }
  end

  after(:each) do
    Sidekiq::Testing.fake!
    Dataset.set_callback(:update, :after, :update_dataset_in_github)
  end

  it 'updates the description of a file' do
    put "/api/datasets/#{@dataset.id}/files/#{@file.id}", params: {
      file: {
        description: 'My shiny new amazing description'
      }
    }, headers: { 'Authorization' => "Token token=#{@user.api_key}" }

    @dataset.reload

    expect(@dataset.dataset_files.last.description).to eq('My shiny new amazing description')
  end

  pending it 'updates a file' do
    Dataset.set_callback(:update, :after, :update_dataset_in_github)

    filename = 'shoes-cotw.csv'
    path = File.join(Rails.root, 'spec', 'fixtures', filename)

    expect(@repo).to receive(:update_file).with("data/test-data.csv", File.read(path))
    expect(@repo).to receive(:update_file).with("data/test-data.md", instance_of(String))
    expect(@repo).to receive(:update_file).with("datapackage.json", instance_of(String))
    expect(@repo).to receive(:update_file).with("_config.yml", instance_of(String))
    expect(@repo).to receive(:save)

    allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(path))

    put "/api/datasets/#{@dataset.id}/files/#{@file.id}", params: {
      file: {
        file: fixture_file_upload(path)
      }
    }, headers: {'Authorization' => "Token token=#{@user.api_key}"}
  end
end
