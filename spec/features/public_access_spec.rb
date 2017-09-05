require "rails_helper"

feature "A visiting, non-logged in user", type: :feature do

  before(:each) do
    visit root_path
    expect(page).to have_content "Publish data easily, quickly and correctly"
    expect(page).to have_content "Sign in with Github"
  end

  context "can access the home page" do
    scenario "and datasets" do
      click_link "All datasets"
      expect(page).to have_content "You currently have no datasets"
    end

    scenario "and can see a list of datasets when there are some" do
      FactoryGirl.create(:dataset, name: 'Woof', url: 'https://meow.com', owner_avatar: 'https://meow.com')
      click_link "All datasets"
      expect(page).to have_content "Woof"
    end


  end

  # scenario "visitor can access the home page API page" do
  #   # requires Javascript capybara...
  #   pending "awaiting set up for Javascript"
  #   # visit root_path
  #   # click_link "API"
  #   # wait_for_ajax
  #   # expect(page).to have_content 'Octopub API'
  # end

  context "can not access" do

    after(:each) do
      expect(page).to have_content "You must be logged in to do that"
    end

    it "new dataset path" do 
      visit new_dataset_path 
    end
    it "edit dataset path" do 
      @dataset = FactoryGirl.create(:dataset)
      visit edit_dataset_path(@dataset.id)
    end
    it "new dashboard path" do 
      visit dashboard_path 
    end
    it "me path" do 
      visit me_path 
    end
    it "new dataset file schema path" do 
      visit new_dataset_file_schema_path 
    end
  end 

  context "can not access - forbidden" do
    after(:each) do
      expect(page).to have_content "You do not have permission to view that page or resource"
    end
    it "users path" do 
      visit users_path 
    end
  end 

end