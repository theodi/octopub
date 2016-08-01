require 'spec_helper'

describe 'GET /jobs/:id' do

  it 'returns running if there are no errors or datasets yet' do
    get "api/jobs/my-cool-id"

    expect(JSON.parse(response.body)['status']).to eq('running')
  end

  it 'returns errors if an error has ocurred' do
    create(:error, job_id: 'my-broken-job', messages: ['You are a plum', 'You missed a thing'])

    get "api/jobs/my-broken-job"

    json = JSON.parse(response.body)

    expect(json['status']).to eq('error')
    expect(json['errors']).to eq(['You are a plum', 'You missed a thing'])
  end

  it 'returns a link to the dataset once it has been created sucessfully' do
    dataset = create(:dataset, job_id: 'my-working-job')

    get "api/jobs/my-working-job"

    json = JSON.parse(response.body)

    expect(json['status']).to eq('complete')
    expect(json['dataset_url']).to eq("/api/datasets/#{dataset.id}.json")
  end

end
