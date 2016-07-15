require 'spec_helper'

describe UsersController, type: :controller do
  render_views

  before(:each) do
    @user = create(:user, email: "test@example.com", name: "TestyMcTest")
  end

  it 'returns 403 if user is not logged in' do
    get :edit

    expect(response.code).to eq("403")
  end

  it "shows a user's details" do
    sign_in @user

    get :edit

    expect(response.body).to match(/#{@user.name}/)
    expect(response.body).to match(/#{@user.email}/)
    expect(response.body).to match(/#{@user.api_key}/)
  end

  it "updates a user's email" do
    sign_in @user

    put :update, user: {
      email: 'newemail@example.com'
    }

    expect(@user.email).to eq('newemail@example.com')
  end

  it "lists a user's organizations" do
    sign_in @user
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

    get :organizations

    expect(response.body).to eq({
      organizations: [
        {
          login: 'org1'
        },
        {
          login: 'org2'
        },
        {
          login: 'org3'
        }
      ]
    }.to_json)
  end

end
