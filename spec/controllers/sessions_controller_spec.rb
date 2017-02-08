require 'rails_helper'

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
      request = get :create, params: { provider: 'github' }

      expect(request).to redirect_to('/')
      expect(controller.session[:user_id]).to eq(@user.id)
    end

    it 'queues up a dataset refresh' do
      expect {
        get :create, params: { provider: 'github' }
      }.to change(Sidekiq::Extensions::DelayedClass.jobs, :size).by(1)
    end

    it 'returns an API key' do
      allow(controller).to receive(:referer) { 'comma-chameleon' }

      request = get :create, params: { provider: 'github' }

      expect(request.body).to redirect_to("/redirect?api_key=#{@user.api_key}")
    end
  end

  context('#destroy') do

    it 'signs a user out' do
      get :create, params: { provider: 'github' }
      expect(controller.session[:user_id]).to eq(@user.id)

      request = get :destroy

      expect(request).to redirect_to('/')
      expect(controller.session[:user_id]).to eq(nil)
    end
  end

  context('#redirect') do
    it 'renders nothing' do
      get :redirect
      expect(controller.response.body).to be_blank
    end
  end
end
