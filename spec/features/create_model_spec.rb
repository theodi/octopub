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
			click_link "Schemas / Models"
			expect(page).to have_content 'You currently have no dataset file schemas, why not add one?'
		end

		context 'logged in user has no model' do
			scenario 'can create a model' do
				click_link 'Create a new model'
				before_models = Model.count

				within 'form' do
					
				end
			end
		end
	end
end