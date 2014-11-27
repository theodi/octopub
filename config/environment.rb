# Load the Rails application.
require File.expand_path('../application', __FILE__)

Mime::Type.register "application/atom+xml", :feed

# Initialize the Rails application.
Rails.application.initialize!
