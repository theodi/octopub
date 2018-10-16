require 'rails_helper'

describe ModelsController, type: :controller do

	before(:each) do
		@user = create(:user)
	end

	describe 'index' do

		it "gets the right number of models" do
			sign_in @user
			2.times { |i| create(:model, user: @user)}
			get 'index'
			expect(assigns(:models).count).to eq(2)
		end
	end
end