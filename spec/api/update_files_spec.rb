require 'spec_helper'

describe 'PUT /datasets/:id/files/:file_id' do

  before(:each) do
    Sidekiq::Testing.inline!

    @user = create(:user, name: "User McUser", email: "user@user.com")
    @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
      create(:dataset_file, title: "Test Data")
    ])
    @file = @dataset.dataset_files.last

    @repo = double(GitData)
    expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  it 'updates the description of a file' do
    put "/api/datasets/#{@dataset.id}/files/#{@file.id}", {
      file: {
        description: 'My shiny new amazing description'
      }
    },
    {'Authorization' => "Token token=#{@user.api_key}"}

    @dataset.reload

    expect(@dataset.dataset_files.last.description).to eq('My shiny new amazing description')
  end

  it 'updates a file' do
    Dataset.set_callback(:update, :after, :update_in_github)

    filename = 'shoes-cotw.csv'
    path = File.join(Rails.root, 'spec', 'fixtures', filename)

    expect(@repo).to receive(:update_file).with("data/test-data.csv", File.read(path))
    expect(@repo).to receive(:update_file).with("data/test-data.md", instance_of(String))
    expect(@repo).to receive(:update_file).with("datapackage.json", instance_of(String))
    expect(@repo).to receive(:save)

    put "/api/datasets/#{@dataset.id}/files/#{@file.id}", {
      file: {
        file: fixture_file_upload(path)
      }
    },
    {'Authorization' => "Token token=#{@user.api_key}"}
  end

end
