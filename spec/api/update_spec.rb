require 'spec_helper'

describe 'PUT /datasets/:id' do

  before(:each) do
    Sidekiq::Testing.inline!
    skip_callback_if_exists(Dataset, :create, :after, :create_in_github)

    @user = create(:user, name: "User McUser", email: "user@user.com")
    @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
      create(:dataset_file, filename: 'test-data.csv')
    ])

    @repo = double(GitData)
    expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
  end

  after(:each) do
    Sidekiq::Testing.fake!
    Dataset.set_callback(:create, :after, :create_in_github)
  end

  it 'updates a dataset sucessfully' do
    put "/api/datasets/#{@dataset.id}",
    {
      dataset: {
        description: "My new description",
        publisher_name: "New Publisher",
        publisher_url: "http://www2.example.org",
        license: "cc0",
        frequency: "Annual"
      }
    },
    {'Authorization' => "Token token=#{@user.api_key}"}

    @dataset.reload

    expect(@dataset.description).to eq("My new description")
    expect(@dataset.publisher_name).to eq("New Publisher")
    expect(@dataset.publisher_url).to eq("http://www2.example.org")
    expect(@dataset.license).to eq("cc0")
    expect(@dataset.frequency).to eq("Annual")

    expect(response.code).to eq '202'
  end

end
