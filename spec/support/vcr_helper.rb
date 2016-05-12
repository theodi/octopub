require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :once }
  c.allow_http_connections_when_no_cassette = true
  c.filter_sensitive_data("<GITHUB_TOKEN>") { ENV['GITHUB_TOKEN'] }
  c.configure_rspec_metadata!
end
