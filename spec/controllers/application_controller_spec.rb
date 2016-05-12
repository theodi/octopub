require 'spec_helper'

describe ApplicationController, type: :controller do
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
       controller.params[:api_key] = user.api_key
       controller.instance_eval{ current_user }

       expect(controller.instance_eval{ @current_user }).to eq(user)
     end

     it "returns nil if there is no user" do
       controller.session[:user_id] = nil
       controller.instance_eval{ current_user }

       expect(controller.instance_eval{ @current_user }).to eq(nil)
     end

   end
end
