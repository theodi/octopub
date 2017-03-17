require 'rails_helper'

describe RestrictedUsersController, type: :controller do
  render_views

  let(:admin) { create(:admin) }

  before(:each) do
    @user = create(:user)
  end

  it 'returns 403 if user is not logged in' do
    get :edit, params: { id: @user.id }
    expect(response.code).to eq("403")
  end

  describe "when logged in" do

    before(:each) do
      sign_in admin
    end

    it "shows a user's details" do
      get :edit, params: { id: @user.id }
      expect(CGI.unescapeHTML(response.body)).to match(/#{@user.name}/)
      expect(response.body).to match(/#{@user.email}/)
      expect(response.body).to match(/#{@user.api_key}/)
    end

    it "updates a user's email" do
      put :update, params: { id: @user.id, user: { email: 'newemail@example.com' }}
      @user.reload
      expect(@user.email).to eq 'newemail@example.com'
    end

    it "updates a user's role" do
      expect(@user.role).to eq 'publisher'
      put :update, params: { id: @user.id, user: { role: 'superuser' }}
      @user.reload
      expect(@user.role).to eq 'superuser'
    end
  end
end
