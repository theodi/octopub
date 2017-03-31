require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Publisher can update a Dataset File Schema", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

  it "by visiting the edit page" do
    Sidekiq::Testing.inline! 
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

    visit edit_dataset_file_schema_path(dataset_file_schema_1)
    Sidekiq::Testing.fake! 
  end

  it "but not if it has datasets" do
    Sidekiq::Testing.inline! 
    dataset_file_schema_name = 'this-is-your-schema'
    schema_path = get_fixture_schema_file('good-schema.json')
    filename = 'valid-schema.csv'
    @url_for_schema = url_for_schema_with_stubbed_get_for(schema_path)
    string_io_for_data_file = get_string_io_from_fixture_file(filename) 

    dataset_file_schema = DatasetFileSchemaService.new(
      dataset_file_schema_name,
      'existing schema description',
      @url_for_schema,
      @user,
      @user.name
    ).create_dataset_file_schema

    dataset = create :dataset, user: @user,
        dataset_files: [
          create(:dataset_file, filename: filename, file: string_io_for_data_file, storage_key: filename, dataset_file_schema: dataset_file_schema)
        ]

    visit dataset_file_schema_path(dataset_file_schema)
    expect(page.has_no_button?('Edit')).to be true
    Sidekiq::Testing.fake! 
  end
end