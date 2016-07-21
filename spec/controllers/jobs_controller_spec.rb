require 'spec_helper'

describe JobsController, type: :controller do

  it 'returns running if there are no errors or datasets yet' do
    get 'show', id: 'my-cool-id', format: :json

    expect(JSON.parse(response.body)['status']).to eq('running')
  end

  it 'returns errors if an error has ocurred' do
    create(:error, job_id: 'my-broken-job', messages: ['You are a plum', 'You missed a thing'])

    get 'show', id: 'my-broken-job', format: :json

    json = JSON.parse(response.body)

    expect(json['status']).to eq('error')
    expect(json['errors']).to eq(['You are a plum', 'You missed a thing'])
  end

  it 'returns a link to the dataset once it has been created sucessfully' do
    dataset = create(:dataset, job_id: 'my-working-job')

    get 'show', id: 'my-working-job', format: :json

    json = JSON.parse(response.body)

    expect(json['status']).to eq('complete')
    expect(json['dataset_url']).to eq(dataset_url(dataset, format: :json))
  end

end
