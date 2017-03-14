require 'rails_helper'

describe 'PUT /datasets/:id' do

  before(:each) do
    Sidekiq::Testing.inline!
    skip_callback_if_exists(Dataset, :create, :after, :create_repo_and_populate)
    skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)
   
    @user = create(:user)
    @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
      create(:dataset_file, filename: 'test-data.csv')
    ])

    @repo = double(GitData)
    expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
  end

  after(:each) do
    Sidekiq::Testing.fake!
    Dataset.set_callback(:create, :after, :create_repo_and_populate)
    Dataset.set_callback(:update, :after, :update_dataset_in_github)
  end

  it 'updates a dataset sucessfully' do
    license = Octopub::API_LICENCES.sample
    frequency = Octopub::PUBLICATION_FREQUENCIES.sample
    put "/api/datasets/#{@dataset.id}", params:
    {
      dataset: {
        description: "My new description",
        publisher_name: "New Publisher",
        publisher_url: "http://www2.example.org",
        license: license,
        frequency: frequency
      }
    },
    headers: {'Authorization' => "Token token=#{@user.api_key}"}

    @dataset.reload

    expect(@dataset.description).to eq("My new description")
    expect(@dataset.publisher_name).to eq("New Publisher")
    expect(@dataset.publisher_url).to eq("http://www2.example.org")
    expect(@dataset.license).to eq(license)
    expect(@dataset.frequency).to eq(frequency)

    expect(response.code).to eq '202'
  end

end
