# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'

require 'git_data'
require 'database_cleaner'
require 'factory_bot'
require 'omniauth'

require 'webmock/rspec'
require 'sidekiq/testing'
require 'timecop'

require 'features/user_and_organisations'

require 'support/odlifier_licence_mock'
require 'support/vcr_helper'
require 'support/fake_data'

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.include_context 'user and organisations', :include_shared => true
  config.include_context 'odlifier licence mock', :include_shared => true

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.include FactoryBot::Syntax::Methods
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.before(:each) do |example|
    # Stub out repository checking for all tests apart from GitData
    allow_any_instance_of(Octokit::Client).to receive(:repository?) { false } unless example.metadata[:described_class] == GitData

    unless example.example_group.description == 'FileStorageService'
      allow(FileStorageService).to receive(:get_string_io) do |storage_key|
        get_string_io_from_fixture_file(storage_key)
      end
      allow(FileStorageService).to receive(:create_and_upload_public_object) do |filename, body|
        obj = double(Aws::S3::Object)
        allow(obj).to receive(:public_url) { "https://example.org/uploads/1234/#{filename}" }
        allow(obj).to receive(:key) do |filename|
          "uploads/1234/#{filename}"
        end
        obj
      end
    end
  end

  # This overrides always true in the spec_helper file
  config.around(:each, type: :helper) do |ex|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = false
      ex.run
      mocks.verify_partial_doubles = true
    end
  end

  # This overrides always true in the spec_helper file
  # Added to allow stubbing of current_user in view specs:
  # https://github.com/rspec/rspec-rails/issues/1076
  config.around(:each, type: :view) do |ex|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = false
      ex.run
      mocks.verify_partial_doubles = true
    end
  end

end

def compare_schemas_after_processing(original, compare_to)
  sorted_fields = normalise_schema(original)
  sorted_example_output = normalise_schema(compare_to)
  sorted_fields.each_with_index do |field, index|
    if field['constraints']
      field['constraints'] = field['constraints'].sort.to_h
      sorted_example_output[index]['constraints'] = sorted_example_output[index]['constraints'].sort.to_h
      expect(field['constraints']).to eq (sorted_example_output[index]['constraints'])
    end
  end
  expect(sorted_fields).to eq sorted_example_output
end

def normalise_schema(schema)
  normalised = schema
  if schema.instance_of?(Hash) && schema.key?("fields")
    normalised = schema['fields']
  elsif schema.instance_of?(TableSchema::Schema)
    normalised = schema.fields
  end
  normalised.sort_by { |k| k["name"] }
end

def sign_in(user)
  allow_any_instance_of(ApplicationController).to receive(:session) { {user_id: user.id} }
end

def sign_out
  allow_any_instance_of(ApplicationController).to receive(:session) { {} }
end

def set_api_key(user)
  sign_out # Make sure we haven't got any sessions hanging around
  request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.api_key)
end

def read_fixture_schema_file(file_name)
  File.read(get_fixture_schema_file(file_name))
end

def get_fixture_schema_file(file_name)
  get_fixture_file("schemas/#{file_name}")
end

def read_fixture_file(file_name)
  File.read(get_fixture_file(file_name))
end

def get_fixture_file(file_name)
  File.join(Rails.root, 'spec', 'fixtures', file_name)
end

def get_json_from_url(url)
  JSON.generate(JSON.load(open(url).read.force_encoding("UTF-8")))
end

def get_string_io_from_fixture_file(storage_key)
  unless storage_key.nil?
    filename = storage_key.split('/').last
    StringIO.new(read_fixture_file(filename))
  end
end

def get_string_io_schema_from_fixture_file(storage_key)
  unless storage_key.nil?
    filename = storage_key.split('/').last
    StringIO.new(read_fixture_file("schemas/#{filename}"))
  end
end

def url_with_stubbed_get_for(path)
  filename = path.split('/').last
  url = "https://example.org/uploads/#{SecureRandom.uuid}/#{filename}"
  stub_request(:get, url).to_return(body: File.read(path))
  url
end

def url_with_stubbed_get_for_storage_key(storage_key, file_name)
  url = "https://example.org/#{storage_key}"
  stub_request(:get, url).to_return(body: read_fixture_file(file_name))
  url
end

def url_with_stubbed_get_for_fixture_file(file_name)
  path = File.join(Rails.root, 'spec', 'fixtures', file_name)
  url = "https://example.org/uploads/#{SecureRandom.uuid}/#{file_name}.csv"
  stub_request(:get, url).to_return(body: File.read(path))
  url
end

def url_for_schema_with_stubbed_get_for(path)
  url = "https://example.org/uploads/#{SecureRandom.uuid}/schema.json"
  stub_request(:get, url).to_return(body: File.read(path))
  url
end

def mock_pusher(channel_id)
  mock_client = double(Pusher::Channel)
  expect(Pusher).to receive(:[]).with(channel_id) { mock_client }
  allow(mock_client).to receive(:trigger)
  mock_client
end

def skip_callback_if_exists(thing, name, kind, filter)
  if name == :create && any_callbacks?(thing._create_callbacks, name, kind, filter)
    thing.skip_callback(name, kind, filter)
  end
  if name == :update && any_callbacks?(thing._update_callbacks, name, kind, filter)
    thing.skip_callback(name, kind, filter)
  end
end

def any_callbacks?(callbacks, name, kind, filter)
  callbacks.select { |cb| cb.name == name && cb.kind == kind && cb.filter == filter }.any?
end
