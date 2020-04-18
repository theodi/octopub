require 'rails_helper'

describe ModelsController, type: :controller do

	describe 'new' do
		it "returns http success" do
			get :new
			expect(response).to be_success
		end
	end
end