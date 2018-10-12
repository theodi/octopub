require "rails_helper"
require 'features/user_and_organisations'

feature 'Add model', type: :feature do
	include_context 'user and organisations'

	before(:each) do
		Sidekiq::Testing.inline!
		visit root_path
	end

	after(:each) do
		Sidekiq::Testing.fake!
	end

	context "logged in visitor has models and" do

		before(:each) do
			create(:model, name: 'good model', description: 'good model description', user: @user)
			click_link "Models"
		end

		it 'can access the dashboard' do
			expect(page).to have_content "Your models"
		end
	end
end