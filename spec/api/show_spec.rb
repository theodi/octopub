require 'spec_helper'

describe 'GET /datasets/:id', vcr: { :match_requests_on => [:host, :method] } do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  it 'gets a file with a particular id' do
    dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
      create(:dataset_file, filename: 'test-data.csv')
    ])

    get "/api/datasets/#{dataset.id}", headers: {'Authorization' => "Token token=#{@user.api_key}"}

    json = JSON.parse(response.body)

    expect(json['url']).to eq("/api/datasets/#{dataset.id}.json")
    expect(json['name']).to eq(dataset.name)
    expect(json['files'].count).to eq(1)
  end

  it 'returns 403 if the user does not own a particular dataset' do
    other_user = create(:user, name: "User 2", email: "other-user@user.com")
    dataset = create(:dataset, name: "Dataset", user: other_user)

    get "/api/datasets/#{dataset.id}", headers: {'Authorization' => "Token token=#{@user.api_key}"}

    expect(response.code).to eq("403")
  end

  it 'returns 401 if the user is not signed in' do
    dataset = create(:dataset, name: "Dataset", user: @user)

    get "/api/datasets/#{dataset.id}"

    expect(response.code).to eq("401")
  end

end
