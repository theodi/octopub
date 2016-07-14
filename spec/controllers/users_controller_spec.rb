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
    orgs = [
      {
        name: "org1",
        role: "admin"
      },
      {
        name: "org2",
        role: "admin"
      },
    ]

    expect(@user.octokit_client).to receive(:org_memberships) {
      orgs
    }.once

    get :organizations

    expect(response.body).to eq({
      organizations: orgs
    }.to_json)
  end

end
