require "rails_helper"
require 'features/user_and_organisations'

feature "Add dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'user and organisations'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:wonky_file) { get_fixture_schema_file('good-schema.json') }
  let(:common_name) { Faker::Lorem.word }
  let(:page_copy) { 'Create a new Schema from a CSV Data File' }
  let(:infer_schema_filename) { 'schemas/infer-from/data_infer.csv' }
  let(:uuid) { 'd42c4843-bc5b-4c62-b161-a55356125b59' }
  let(:csv_storage_key) { "uploads/#{uuid}/data_infer.csv" }
  let(:wonky_storage_key) { "uploads/#{uuid}/good-schema.json" }
  let(:infer_schema_csv_url) { url_with_stubbed_get_for_storage_key(csv_storage_key, infer_schema_filename) }


  before(:each) do
    visit root_path
    click_link 'Schemas'
    expect(page).to have_content 'You currently have no dataset file schemas, why not add one?'
  end

  context "logged in visitors has no schemas" do
    scenario "and can infer a dataset file schema from a data file" do
      click_link 'Infer a new dataset file schema'
      expect(page).to have_content page_copy

      before_datasets = DatasetFileSchema.count

      within 'form' do
        expect(page).to have_content @user.github_username
        select @user.github_username, :from => "inferred_dataset_file_schema_owner_username"
        fill_in 'inferred_dataset_file_schema_name', with: "#{common_name}-schema-name"
        fill_in 'inferred_dataset_file_schema_description', with: "#{common_name}-schema-description"
        attach_file('inferred_dataset_file_schema_csv_url', data_file)
        click_on 'Submit'
      end

      expect(CGI.unescapeHTML(page.html)).to have_content "Dataset File Schemas for #{@user.name}"
      expect(DatasetFileSchema.count).to be before_datasets + 1
      expect(DatasetFileSchema.last.name).to eq "#{common_name}-schema-name"
    end

    scenario "and can infer a dataset file schema from a data file with categories" do

      category_1 = SchemaCategory.create(name: 'cat1')
      category_2 = SchemaCategory.create(name: 'cat2')
      schema_category_ids = [ category_1.id, category_2.id ]

      click_link 'Infer a new dataset file schema'
      expect(page).to have_content page_copy

      within 'form' do
        expect(page).to have_content @user.github_username
        select @user.github_username, :from => "inferred_dataset_file_schema_owner_username"
        fill_in 'inferred_dataset_file_schema_name', with: "#{common_name}-schema-name"
        fill_in 'inferred_dataset_file_schema_description', with: "#{common_name}-schema-description"
        attach_file('inferred_dataset_file_schema_csv_url', data_file)
        check ('cat1')
        check ('cat2')
        click_on 'Submit'
      end

      expect(CGI.unescapeHTML(page.html)).to have_content "Dataset File Schemas for #{@user.name}"
      dataset_file_schema = DatasetFileSchema.first
      expect(DatasetFileSchema.count).to be 1
      expect(dataset_file_schema.schema_categories).to eq [ category_1, category_2 ]
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
          expect(page).to have_content @user.github_username
          select @user.github_username, :from => "inferred_dataset_file_schema_owner_username"
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
