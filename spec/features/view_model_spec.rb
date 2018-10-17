require 'rails_helper'

feature 'As a logged in user, viewing models', type: :feature do
	include_context 'user and organisations'

	let(:model_name) { Faker::Lorem.word }
	let(:model_description) { Faker::Lorem.sentence }
	let(:publisher) { create(:user) }
	let(:random_publisher) { create(:user) }
	let(:admin) { create(:user, role: :admin) }

	before(:each) do
		OmniAuth.config.mock_auth[:github]
		@model = create(:model, name: model_name, description: model_description, user: publisher)
	end

	context 'as the creator' do

		before(:each) do
			sign_in publisher
		end

		it 'can view models' do
			visit models_path
			click_on(@model.name)
			expect(page).to have_content "#{@model.name}"
		end
	end

	pending 'cannot view other users models' do

	end

	pending 'can view other users models if an admin' do

	end
end