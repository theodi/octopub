require 'spec_helper'

describe 'GET /dashboard' do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  it 'gets all datasets for a user' do
    5.times { |i| create(:dataset, name: "Dataset #{i}") }

    dataset = create(:dataset, user: @user)

    get '/api/dashboard', nil, {'Authorization' => "Token token=#{@user.api_key}"}

    json = JSON.parse(response.body)

    expect(json['datasets'].count).to eq(1)
    expect(json['datasets'].first['name']).to eq(dataset.name)
  end

end
