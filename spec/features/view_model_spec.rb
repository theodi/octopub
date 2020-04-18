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

	after(:each) do
		sign_out
	end

	context 'as the creator' do

		it 'can view models' do
			sign_in publisher
			visit models_path
			click_on(@model.name)
			expect(page).to have_content "#{@model.name}"
		end
	end

	it 'cannot view other users models' do
		sign_in random_publisher
		visit model_path(@model)
		expect(page).to have_content 'You do not have permission'
	end
end