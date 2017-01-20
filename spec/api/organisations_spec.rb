require 'spec_helper'

describe 'GET /user/organisations' do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  it 'lists all datasets' do
    allow(User).to receive(:find_by_api_key) {
      @user
    }

    allow(@user).to receive(:organizations) {
      [
        OpenStruct.new(
          organization: OpenStruct.new({
            login: "org1",
            avatar_url: "http://www.example.org/avatar1.png"
          })
        ),
        OpenStruct.new(
          organization: OpenStruct.new({
            login: "org2",
            avatar_url: "http://www.example.org/avatar2.png"
          })
        ),
        OpenStruct.new(
          organization: OpenStruct.new({
            login: "org3",
            avatar_url: "http://www.example.org/avatar3.png"
          })
        )
      ]
    }

    get '/api/user/organisations', headers: {'Authorization' => "Token token=#{@user.api_key}"}

    expect(response.body).to eq([
      {
        login: 'org1'
      },
      {
        login: 'org2'
      },
      {
        login: 'org3'
      }
    ].to_json)
  end

end
