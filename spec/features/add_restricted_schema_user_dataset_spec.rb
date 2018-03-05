require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Publisher can create a non-GitHub private repo", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

	# Pending as a concept in Octopub is now deprecated
  pending "by uploading a simple dataset" do
    Sidekiq::Testing.inline!

    @user.update(restricted: true)
    dataset_file_schema_name = 'this-is-your-schema'
    schema_path = get_fixture_schema_file('good-schema.json')
    @url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)

    dataset_file_schema_1 = DatasetFileSchemaService.new(
      dataset_file_schema_name,
      'existing schema description',
      @url_for_schema,
      @user,
      @user.name
    ).create_dataset_file_schema

    @user.allocated_dataset_file_schemas << dataset_file_schema_1

    expect(RepoService).to_not receive(:create_repo)
    expect(RepoService).to_not receive(:fetch_repo)
    expect_any_instance_of(DatasetMailer).to receive(:success)

    data_file = get_fixture_file('valid-schema.csv')
    common_name = 'Fri1437'

    visit root_path
    click_link "Add dataset for #{dataset_file_schema_name}"
    expect(page.has_no_field?('dataset[publisher_url]'))
    expect(page.has_no_field?('dataset[publisher_name]'))
    expect(page.has_no_field?('dataset[license]'))
    expect(page.has_no_field?('dataset[publishing_method]'))
    expect(page.has_no_field?('[dataset[frequency]]'))

    expect(page).to have_selector(:link_or_button, "Submit")
    within 'form' do
      complete_form(page, common_name, data_file)
    end

    click_on 'Submit'

    expect(page).to have_content "Your dataset has been queued for creation and should be completed shortly"
    expect(Dataset.count).to be 1
    dataset = Dataset.first

    expect(dataset.name).to eq "#{common_name}-name"
    expect(dataset.owner).to eq @user.name
    expect(dataset.publisher_name).to eq @user.name
    expect(dataset.local_private?).to be true

    dataset_file = dataset.dataset_files.first
    expect(dataset_file.title).to eq "#{common_name}-file-name"
    expect(dataset_file.dataset_file_schema_id).to be dataset_file_schema_1.id

    Sidekiq::Testing.fake!
  end

  def complete_form(page, common_name, data_file, owner = nil, licence = nil)
    dataset_name = "#{common_name}-name"

    fill_in 'dataset[name]', with: dataset_name
    fill_in 'dataset[description]', with: "#{common_name}-description"
    fill_in 'files[][title]', with: "#{common_name}-file-name"
    fill_in 'files[][description]', with: "#{common_name}-file-description"
    attach_file("[files[][file]]", data_file)
    expect(page).to have_selector("input[value='#{dataset_name}']")
  end
end
