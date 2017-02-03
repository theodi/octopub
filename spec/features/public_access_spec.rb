require "rails_helper"

feature "Public access to pages", type: :feature do
  scenario "visitor can access the home page and datasets" do

    visit root_path

    expect(page).to have_content "Publish data easily, quickly and correctly"
    expect(page).to have_content "Sign in with Github"

    click_link "All datasets"

    expect(page).to have_content "You currently have no datasets"
  end

  scenario "visitor can access the home page, API page and can see a list of datasets" do

    FactoryGirl.create(:dataset, name: 'Woof', url: 'https://meow.com', owner_avatar: 'https://meow.com')

    visit root_path

    expect(page).to have_content "Publish data easily, quickly and correctly"
    expect(page).to have_content "Sign in with Github"

    click_link "All datasets"

    expect(page).to have_content "Woof"
  end


  # scenario "visitor can access the home page API page" do
  #   # requires Javascript capybara...
  #   pending "awaiting set up for Javascript"

  #   # visit root_path

  #   # click_link "API"
  #   # wait_for_ajax

  #   # expect(page).to have_content 'Octopub API'
  # end
end