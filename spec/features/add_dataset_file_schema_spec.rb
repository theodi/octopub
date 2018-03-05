require "rails_helper"
require 'features/user_and_organisations'

feature "Add dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'user and organisations'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:common_name) { Faker::Lorem.word }

  before(:each) do
    allow(DatasetFileSchemaService).to receive(:read_file_with_utf_8).and_return(read_fixture_schema_file('good-schema.json'))
    allow_any_instance_of(DatasetFileSchema).to receive(:is_schema_otw?).and_return(false)
    visit root_path
    click_link 'Schemas'
    expect(page).to have_content 'You currently have no dataset file schemas, why not add one?'
  end

  context "logged in visitors has no schemas" do
    scenario "and can add a dataset file schema on it's own" do
      click_link 'Add a new dataset file schema'
      before_datasets = DatasetFileSchema.count

      within 'form' do
        expect(page).to have_content @user.github_username
        select @user.github_username, from: "dataset_file_schema_owner_username"
        fill_in 'dataset_file_schema_name', with: "#{common_name}-schema-name"
        fill_in 'dataset_file_schema_description', with: "#{common_name}-schema-description"
        attach_file('dataset_file_schema_url_in_s3', data_file)

        click_on 'Submit'
      end

      dataset_file_schema = DatasetFileSchema.first

      expect(CGI.unescapeHTML(page.html)).to have_content "Dataset File Schemas for #{@user.name}"
      expect(DatasetFileSchema.count).to be before_datasets + 1
      expect(dataset_file_schema.name).to eq "#{common_name}-schema-name"
      expect(dataset_file_schema.restricted).to eq true
      expect(dataset_file_schema.schema_fields).to_not be_empty
    end

    scenario "and can add a dataset file schema with a category" do

      category_1 = SchemaCategory.create(name: 'cat1')
      category_2 = SchemaCategory.create(name: 'cat2')
      schema_category_ids = [ category_1.id, category_2.id ]

      click_link 'Add a new dataset file schema'

      within 'form' do
        expect(page).to have_content @user.github_username
        expect(page).to have_content 'cat1'
        select @user.github_username, from: "dataset_file_schema_owner_username"
        fill_in 'dataset_file_schema_name', with: "#{common_name}-schema-name"
        fill_in 'dataset_file_schema_description', with: "#{common_name}-schema-description"
        attach_file('dataset_file_schema_url_in_s3', data_file)
        check ('cat1')
        check ('cat2')

        click_on 'Submit'
      end

      expect(CGI.unescapeHTML(page.html)).to have_content "Dataset File Schemas for #{@user.name}"
      dataset_file_schema = DatasetFileSchema.first
      expect(DatasetFileSchema.count).to be 1
      expect(dataset_file_schema.schema_categories).to eq [ category_1, category_2 ]
    end

    scenario "and can add a public dataset file schema" do
      click_link 'Add a new dataset file schema'
      before_datasets = DatasetFileSchema.count

      within 'form' do
        expect(page).to have_content @user.github_username
        select @user.github_username, from: "dataset_file_schema_owner_username"
        fill_in 'dataset_file_schema_name', with: "#{common_name}-schema-name"
        fill_in 'dataset_file_schema_description', with: "#{common_name}-schema-description"
        select "Public - any user may access this schema", from: 'dataset_file_schema_restricted'
        attach_file('dataset_file_schema_url_in_s3', data_file)

        click_on 'Submit'
      end

      dataset_file_schema = DatasetFileSchema.first

      expect(DatasetFileSchema.count).to be before_datasets + 1
      expect(dataset_file_schema.name).to eq "#{common_name}-schema-name"
      expect(dataset_file_schema.restricted).to eq false
      expect(dataset_file_schema.schema_fields).to_not be_empty
    end

    context "and gets an error if they do not populate the correct fields" do

      before(:each) do
        click_link 'Add a new dataset file schema'
        expect(page).to have_content 'Add a new Dataset File Schema'
      end

      it "errors if no name" do
        within 'form' do
          fill_in 'dataset_file_schema_description', with: "#{common_name}-schema-description"
          attach_file('dataset_file_schema_url_in_s3', data_file)
          click_on 'Submit'
        end

        expect(page).to have_content 'Add a new Dataset File Schema'
        expect(page).to have_content 'Please give the schema a meaningful name'
      end

      it "errors if no file" do
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
