require 'rails_helper'

describe 'PUT /datasets/:id/files/:file_id', vcr: { :match_requests_on => [:host, :method] } do

  before(:each) do
    Sidekiq::Testing.inline!

    skip_callback_if_exists(Dataset, :create, :after, :create_repo_and_populate)
    skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)
   

    @user = create(:user, name: "User McUser", email: "user@user.com")
    @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
      create(:dataset_file, title: "Test Data")
    ])
    @file = @dataset.dataset_files.last
    args = {}
    @repo = double(GitData)
  #  allow_any_instance_of(User).to receive(:octokit_client).and_return { @repo }
    # allow(@user).to receive(:octokit_client).with(any_args).and_return { p "ARGH" && Octokit::Client.new('1234') }
   allow(@dataset).to receive(:fetch_repo)#.and_return { @repo }

    expect(GitData).to receive(:find).once.with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
  end

  after(:each) do
    Sidekiq::Testing.fake!
    Dataset.set_callback(:create, :after, :create_repo_and_populate)
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

  it 'updates a file' do
    Dataset.set_callback(:update, :after, :update_dataset_in_github)

    filename = 'shoes-cotw.csv'
    path = File.join(Rails.root, 'spec', 'fixtures', filename)

    expect(@repo).to receive(:update_file).with("data/test-data.csv", File.read(path))
    expect(@repo).to receive(:update_file).with("data/test-data.md", instance_of(String))
    expect(@repo).to receive(:update_file).with("datapackage.json", instance_of(String))
    expect(@repo).to receive(:save)

    allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(path))

    put "/api/datasets/#{@dataset.id}/files/#{@file.id}", params: {
      file: {
        file: fixture_file_upload(path)
      }
    }, headers: {'Authorization' => "Token token=#{@user.api_key}"}
  end

end
