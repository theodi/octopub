require "rails_helper"
require 'features/user_and_organisations'

feature "Add dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'user and organisations'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:wonky_file) { get_fixture_schema_file('good-schema.json') }
  let(:common_name) { Faker::Lorem.word }
  let(:page_copy) { 'Create a new Schema from a CSV Data File' }

  before(:each) do
    allow(DatasetFileSchemaService).to receive(:read_file_with_utf_8).and_return(read_fixture_schema_file('good-schema.json'))
    visit root_path
    click_link 'List my dataset file schemas'
    expect(page).to have_content 'You currently have no dataset file schemas, why not add one?'
  end

  context "logged in visitors has no schemas" do
    scenario "and can infer a dataset file schema from a data file" do
      click_link 'Infer a new dataset file schema'
      expect(page).to have_content page_copy

      before_datasets = DatasetFileSchema.count

      within 'form' do
        fill_in 'inferred_dataset_file_schema_name', with: "#{common_name}-schema-name"
        fill_in 'inferred_dataset_file_schema_description', with: "#{common_name}-schema-description"
        attach_file('inferred_dataset_file_schema_csv_url', data_file)

        click_on 'Submit'
      end

      expect(CGI.unescapeHTML(page.html)).to have_content "Dataset File Schemas for #{@user.name}"
      expect(DatasetFileSchema.count).to be before_datasets + 1
      expect(DatasetFileSchema.last.name).to eq "#{common_name}-schema-name"
    end

    context "and gets an error if they do not populate the correct fields" do

      before(:each) do
        click_link 'Infer a new dataset file schema'
        expect(page).to have_content page_copy
      end

      it "errors if no name" do
        within 'form' do

          fill_in 'inferred_dataset_file_schema_description', with: "#{common_name}-schema-description"
          attach_file('inferred_dataset_file_schema_csv_url', data_file)

          click_on 'Submit'
        end

        expect(page).to have_content page_copy
        expect(page).to have_content 'Please give the schema a meaningful name'
      end

      it "errors if no file" do
        within 'form' do
          fill_in 'inferred_dataset_file_schema_name', with: "#{common_name}-schema-name"
          fill_in 'inferred_dataset_file_schema_description', with: "#{common_name}-schema-description"
          click_on 'Submit'
        end

        expect(page).to have_content page_copy
        expect(page).to have_content 'You must have a data file'
      end

      it "errors if file is wrong format" do
        within 'form' do
          fill_in 'inferred_dataset_file_schema_name', with: "#{common_name}-schema-name"
          fill_in 'inferred_dataset_file_schema_description', with: "#{common_name}-schema-description"
          attach_file('inferred_dataset_file_schema_csv_url', wonky_file)
          click_on 'Submit'
        end

        expect(page).to have_content page_copy
        expect(page).to have_content 'Inferring schema from dataset failed'
      end
    end
  end
end

