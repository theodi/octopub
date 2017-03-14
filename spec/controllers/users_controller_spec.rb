require 'rails_helper'

describe UsersController, type: :controller do
  render_views

  before(:each) do
    @user = create(:user)
  end

  it 'returns 403 if user is not logged in' do
    get :edit
    expect(response.code).to eq("403")
  end

  describe "when logged in" do

    before(:each) do
      sign_in @user
    end

    it "shows a user's details" do

      get :edit
      expect(CGI.unescapeHTML(response.body)).to match(/#{@user.name}/)
      expect(response.body).to match(/#{@user.email}/)
      expect(response.body).to match(/#{@user.api_key}/)
    end

    it "updates a user's email" do

      put :update, params: { user: { email: 'newemail@example.com' }}
      @user.reload
      expect(@user.email).to eq('newemail@example.com')
    end

    it "shows an index of users" do
      @user = create(:user, :with_twitter_name)
      get :index
      expect(response.body).to match(/#{@user.email}/)
      expect(response.body).to match(/#{@user.twitter_handle}/)
    end
  end
end
