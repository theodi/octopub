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
  end

  describe "handles permissions" do
    it "an admin can view list of users" do
      @admin = create(:admin, :with_twitter_name)
      sign_in @admin
      expect(@admin.admin?).to be true
      get :index
      expect(response.body).to match(/#{@admin.email}/)
      expect(response.body).to match(/#{@admin.twitter_handle}/)
    end

    it "a publisher cannot view list of users" do
      @user = create(:user)
      sign_in @user
      get :index
      expect(response.body).to have_content "You do not have permission to view that page or resource"
    end

    it "a superuser cannot view list of users" do
      @user = create(:superuser)
      sign_in @user
      get :index
      expect(response.body).to have_content "You do not have permission to view that page or resource"
    end
  end
end
