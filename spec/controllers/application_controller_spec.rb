require 'spec_helper'

describe ApplicationController, type: :controller, vcr: { :match_requests_on => [:host, :method] } do
   describe "GET 'index'" do

     it "returns http success" do
       get 'index'

       expect(response).to be_success
     end

     it "gets the current user" do
       user = create(:user, id: 123)
       controller.session[:user_id] = 123
       controller.instance_eval{ current_user }

       expect(controller.instance_eval{ @current_user }).to eq(user)
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
         "licenses" => [
           {
             "id" => "CC-BY-4.0",
             "name" => "Creative Commons Attribution 4.0"
           },
           {
             "id" => "CC-BY-SA-4.0",
             "name" => "Creative Commons Attribution Share-Alike 4.0"
           },
           {
             "id" => "CC0-1.0",
             "name" => "CC0 1.0"
           },
           {
             "id" => "OGL-UK-3.0",
             "name" => "Open Government Licence 3.0 (United Kingdom)"
           },
           {
             "id" => "ODC-BY-1.0",
             "name" => "Open Data Commons Attribution License 1.0"
           },
           {
             "id" => "ODC-PDDL-1.0",
             "name" => "Open Data Commons Public Domain Dedication and Licence 1.0"
           }
          ]
        })
     end

   end
end
