require "rails_helper"
require 'features/user_and_organisations'

feature "Add dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'user and organisations'

  let(:data_file) {File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv') }

  before(:each) do
    @user = create(:user)
    OmniAuth.config.mock_auth[:github]
    sign_in @user
    allow_any_instance_of(User).to receive(:organizations) { organizations }
    allow_any_instance_of(User).to receive(:github_user) { github_user }
    allow_any_instance_of(DatasetFileSchemaService).to receive(:read_file_with_utf_8).and_return(read_fixture_schema_file('good-schema.json'))
  end



  

  context "logged in visitors has no schemas" do
    scenario "and can add a dataset file schema on it's own" do
      visit root_path

      click_link 'List my dataset file schemas'
      expect(page).to have_content 'You currently have no dataset file schemas, why not add one?'
      click_link 'Add a new dataset file schema'
      common_name = 'Fri1437'

      before_datasets = DatasetFileSchema.count

      within 'form' do
        fill_in 'dataset_file_schema_name', with: "#{common_name}-schema-name"
        fill_in 'dataset_file_schema_description', with: "#{common_name}-schema-description"
        attach_file('dataset_file_schema_url_in_s3', data_file)

        click_on 'Submit'
      end

      expect(page).to have_content "Dataset File Schemas for #{@user.name}"
      expect(DatasetFileSchema.count).to be before_datasets + 1
      expect(DatasetFileSchema.last.name).to eq "#{common_name}-schema-name"
    end

    context "and gets an error if they do not populate the correct fields" do

      before(:each) do
        visit root_path
        click_link 'List my dataset file schemas'
        expect(page).to have_content 'You currently have no dataset file schemas, why not add one?'
        click_link 'Add a new dataset file schema'
        expect(page).to have_content 'Add a new Dataset File Schema'
      end

      it "errors if no name" do
        common_name = 'Fri1437'

        within 'form' do
          fill_in 'dataset_file_schema_description', with: "#{common_name}-schema-description"
          attach_file('dataset_file_schema_url_in_s3', data_file)
          click_on 'Submit'
        end

        expect(page).to have_content 'Add a new Dataset File Schema'
        expect(page).to have_content 'Please give the schema a meaningful name'
      end

      it "errors if no file" do
        common_name = 'Fri1437'

        within 'form' do
          fill_in 'dataset_file_schema_name', with: "#{common_name}-schema-name"
          fill_in 'dataset_file_schema_description', with: "#{common_name}-schema-description"
          click_on 'Submit'
        end

        expect(page).to have_content 'Add a new Dataset File Schema'
        expect(page).to have_content 'You must have a schema file'
      end
    end
  end
end

