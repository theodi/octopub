require 'rails_helper'

describe 'GET /datasets/:id' do

  before(:each) do
    @user = create(:user)
  end

  it 'shows all files for a particular dataset' do
    dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
      create(:dataset_file, title: 'File 1'),
      create(:dataset_file, title: 'File 2')
    ])

    get "/api/datasets/#{dataset.id}/files", headers: {'Authorization' => "Token token=#{@user.api_key}"}

    json = JSON.parse(response.body)

    first_file = dataset.dataset_files.first
    last_file = dataset.dataset_files.last

    expect(json.count).to eq(2)
    expect(json.first['id']).to eq(first_file.id)
    expect(json.first['title']).to eq(first_file.title)

    expect(json.last['id']).to eq(last_file.id)
    expect(json.last['title']).to eq(last_file.title)
  end

end
