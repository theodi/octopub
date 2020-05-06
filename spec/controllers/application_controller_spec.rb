require 'rails_helper'

describe ApplicationController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do
  describe "GET 'index'" do

    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end

    it "checks whether user is signed in" do
      expect(controller).to receive(:render_403)
      controller.check_signed_in?
    end

    it "gets the current user" do
      user = create(:user, id: 123)
      controller.session[:user_id] = 123
      controller.instance_eval{ current_user }

      expect(controller.instance_eval{ @current_user }).to eq(user)
    end

    it "gets the admin user if logged in" do
      user = create(:admin)
      controller.session[:user_id] = user.id
      controller.instance_eval{ admin_user }
      expect(controller.instance_eval{ @current_user }).to eq(user)
    end

    it "does not get the admin user if the user isn't an admin" do
      user = create(:user)
      controller.session[:user_id] = user.id
      controller.instance_eval{ admin_user }
      expect(controller.instance_eval{ admin_user }).to be_nil
    end

    it "gets the current user from an api key" do
      user = create(:user, id: 456)
      controller.request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.api_key)
      controller.instance_eval{ current_user }

      expect(controller.instance_eval{ @current_user }).to eq(user)
    end

    it "returns nil if there is no user" do
      controller.session[:user_id] = nil
      controller.instance_eval{ current_user }

      expect(controller.instance_eval{ @current_user }).to eq(nil)
    end

    it 'lists licenses as JSON' do
      get 'licenses'

      json = JSON.parse(response.body)

      expect(json).to eq({
        "licenses" => [{"id"=>[{"id"=>"OGL-UK-3.0", "name"=>"OGL (Open Government Licence 3.0 UK)"}], "name"=>"Government"}, {"id"=>[{"id"=>"CC-BY-4.0", "name"=>"CC BY 4.0 (Creative Commons - Attribution 4.0 International)"}, {"id"=>"CC-BY-SA-4.0", "name"=>"CC BY-SA 4.0 (Creative Commons - Attribution-ShareAlike 4.0 International)"}], "name"=>"Creative Commons"}, {"id"=>[{"id"=>"OGL-UK-3.0", "name"=>"ODC BY 1.0 (Open Data Commons - Attribution License 1.0)"}, {"id"=>"ODbL-1.0", "name"=>"ODbL 1.0 (Open Data Commons - Open Database License 1.0)"}], "name"=>"Open Data Commons"}]
      })
    end
  end
end
