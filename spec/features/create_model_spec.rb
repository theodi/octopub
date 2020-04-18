require "rails_helper"
require 'features/user_and_organisations'

feature 'Publisher can create a model', type: :feature do
	include_context 'user and organisations'

	before(:each) do
		Sidekiq::Testing.inline!
	end

	after(:each) do
		Sidekiq::Testing.fake!
	end

	it "by entering details in a form" do

		new_name = 'Fri1437'
		new_description = Faker::Lorem.sentence
		before_models = Model.count

		visit root_path
		click_link "Schemas / Models"
		expect(page).to have_content 'You currently have no dataset file schemas, why not add one?'

		click_link 'Create a new model'
		expect(page).to have_content('Create a model')

		within 'form' do
			complete_form(new_name, new_description)
		end

		expect(Model.count).to be before_models + 1
		expect(Model.last.name).to eq "#{new_name}"
	end

	def complete_form(name, description)
		fill_in 'model[name]', with: name
		fill_in 'model[description]', with: description
		click_button 'Create'
	end
end