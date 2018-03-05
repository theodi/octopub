require "rails_helper"

feature "Logged in admin access to pages", type: :feature do
  include_context 'user and organisations'

  before(:each) do
    @admin = create(:admin, name: "Frank O'Ryan")
    OmniAuth.config.mock_auth[:github]
    sign_in @admin
		puts root_path
    visit root_path
  end

  pending "logged in admins can view user list" do
    expect(page).to have_content "All your data collections"
    visit users_path
    expect(page).to have_content "Users"
  end

  pending "logged in admins can view user their own user information with no dataset file schemas" do
    dataset = create(:dataset, user: @admin)
    expect(page).to have_content "Users"
    visit users_path
    within 'table' do
      click_on(@admin.name)
    end
    expect(page).to have_content "User Details"
    expect(page).to have_content @admin.name
    expect(page).to have_content "User's Datasets"
    expect(page).to have_content dataset.name
    expect(page).to_not have_content "User's Dataset File Schemas"
  end

  it "logged in admins can view user their own user information with dataset file schemas" do
    dataset = create(:dataset, user: @admin)
    dataset_file_schema = create(:dataset_file_schema, user: @admin)

    visit user_path(@admin)
    expect(page).to have_content "User Details"
    expect(page).to have_content @admin.name
    expect(page).to have_content "User's Datasets"
    expect(page).to have_content dataset.name
    expect(page).to have_content "User's Dataset File Schemas"
  end

  context "other user's information" do

    before(:each) do
      @publisher = create(:user)
    end

    context "logged in admins can view" do
      pending "public dataset" do
        dataset = create(:dataset, user: @publisher)
        expect(page).to have_content "Users"
        visit users_path
        within 'table' do
          click_on(@publisher.name)
        end
        expect(page).to have_content "User Details"
        expect(page).to have_content @publisher.name
        expect(page).to have_content "User's Datasets"
        expect(page).to have_content dataset.name
      end

      pending "private dataset files" do
        dataset_file = create(:dataset_file)
        dataset = create(:dataset, user: @publisher, dataset_files: [ dataset_file ], publishing_method: :local_private)

        expect(page).to have_content "Users"
        visit users_path
        within 'table' do
          click_on(@publisher.name)
        end
        expect(page).to have_content "User Details"
        expect(page).to have_content @publisher.name
        expect(page).to have_content "User's Datasets"
        expect(page).to have_content dataset.name
        within 'table' do
          click_on(dataset.name)
        end
        expect(page).to have_content "#{dataset.name}"
      end
    end

    pending "logged in admins can view in user list" do
      expect(page).to have_content "Users"
      visit users_path
      expect(page).to have_content "Users"
      expect(page).to have_content @admin.name
      expect(page).to have_content @publisher.name
    end
  end
end
