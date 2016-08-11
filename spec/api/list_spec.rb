require 'spec_helper'

describe 'GET /datasets' do

  it 'lists all datasets' do
    5.times { |i| create(:dataset, name: "Dataset #{i}") }
    get '/api/datasets'

    json = JSON.parse(response.body)

    expect(json.count).to eq(5)
    expect(response.content_type).to eq("application/json")
  end

end
