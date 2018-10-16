require 'rails_helper'

describe ModelsController, type: :controller do

	before(:each) do
		@user = create(:user)
		@other_user = create(:user, name: "User McUser 2", email: "user2@user.com")
		allow(controller).to receive(:current_user) { @user }
	end

	describe 'index' do

		before(:each) do
			sign_in @user
			2.times { |i| create(:model, user: @user)}
		end

		it "gets the right number of models" do
			get 'index'
			expect(assigns(:models).count).to eq(2)
		end

		it 'gets the right number of models and not someone elses' do
			get 'index'
			create(:model, user: @other_user)
			expect(assigns(:models).count).to eq(2)
		end
	end

	describe 'new' do
		it "returns http success" do
			get :new
			expect(response).to be_success
		end
	end
end