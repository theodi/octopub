require 'rails_helper'

describe UsersController, type: :controller do
  render_views

  before(:each) do
    @user = create(:user, name: "Molly O'Woof woof")
  end

  it 'returns 403 if user is not logged in' do
    get :edit

    expect(response.code).to eq("403")
  end

  it "shows a user's details" do
    sign_in @user

    get :edit
    expect(CGI.unescapeHTML(response.body)).to match(/#{@user.name}/)
    expect(response.body).to match(/#{@user.email}/)
    expect(response.body).to match(/#{@user.api_key}/)
  end

  it "updates a user's email" do
    sign_in @user

    put :update, params: { user: { email: 'newemail@example.com' }}

    @user.reload
    expect(@user.email).to eq('newemail@example.com')
  end

end
