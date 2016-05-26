ENV['RAILS_ENV'] ||= 'test'

require 'coveralls'
Coveralls.wear!('rails')

require File.expand_path('../../config/environment', __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'database_cleaner'
require 'factory_girl'
require 'omniauth'
require 'support/vcr_helper'
require 'support/fake_data'

DatabaseCleaner.strategy = :truncation
OmniAuth.config.test_mode = true

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.include FactoryGirl::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.around(:each, type: :helper) do |ex|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = false
      ex.run
      mocks.verify_partial_doubles = true
    end
  end

  config.infer_spec_type_from_file_location!
end

def sign_in(user)
  allow_any_instance_of(ApplicationController).to receive(:current_user) { user }
end
