require 'spec_helper'

describe SessionsController, type: :controller do

  before(:each) do
    @auth = {
      "provider" => "github",
      "uid" => "1213232",
      "info" => {
        "nickname" => "user-mcuser",
        "email" => "user@example.com"
      },
      "credentials" => {
        "token" => "21312313233"
      }
    }

    allow(controller).to receive(:auth) { @auth }
    @user = create(:user, id: 123, provider: @auth['provider'], uid: @auth['uid'])
  end

  context('#create') do

    it 'signs a user in' do
      request = get :create, provider: 'github'

      expect(request).to redirect_to('/')
      expect(controller.session[:user_id]).to eq(@user.id)
    end

    it 'returns an API key' do
      allow(controller).to receive(:format) { 'json' }

      request = get :create, provider: 'github'

      expect(request.body).to eq({
        api_key: @user.api_key
      }.to_json)
      expect(request.content_type).to eq('application/json')
    end
  end

  context('#destroy') do

    it 'signs a user out' do
      get :create, provider: 'github'
      expect(controller.session[:user_id]).to eq(@user.id)

      request = get :destroy

      expect(request).to redirect_to('/')
      expect(controller.session[:user_id]).to eq(nil)
    end

  end

end
