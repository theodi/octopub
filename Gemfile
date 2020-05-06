source 'https://rubygems.org'

ruby "2.6.5"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.3'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Postgres default
gem 'pg'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

# Git hosted gems
gem 'csv2json', git: 'https://github.com/theodi/csv2json.git'
gem 'csv2rest', git: 'https://github.com/theodi/csv2rest.git'
gem 'alternate_rails', '~> 5.0.0', git: 'https://github.com/theodi/alternate-rails.git'

gem 'csvlint', '~> 0.4'

# New way of validating schemas
gem 'tableschema', '0.3.0'

# User related
gem 'omniauth-github'
gem 'cancancan', '~> 2.1'

# Bootstrap and view stuff
gem 'bootstrap-sass', '~> 3.4.1'
gem 'font-awesome-sass'
gem 'autoprefixer-rails'
gem 'rails-bootstrap-helpers'
gem 'bootstrap-select-rails'
gem 'bootstrap_form', '~> 2.7'
gem 'bootstrap-table-rails', '1.12.1'
gem 'emd'
gem 'jquery-validation-rails'
gem 'leaflet-rails'
gem 'sprockets', '~>3.0'

# Logging and debug
gem 'awesome_print'

# API functionality
gem 'grape'
gem 'grape-route-helpers'
gem 'grape-swagger'
gem 'grape-swagger-entity'

# Markdown processing, rendering & syntax highlighting
gem 'redcarpet'
gem 'rouge'
gem 'coderay'

# Exception handling
gem 'airbrake'

# External services
gem 'twitter'
gem 'octokit'
gem 'git'
gem 'odlifier'
gem 'aws-sdk-s3', '~> 1'
gem 'pusher'
gem 'certificate-factory'
gem 'rgeo'
gem 'rgeo-shapefile'
gem 'rgeo-geojson'
gem 'dbf'

# Queues
gem 'sidekiq'

# General stuff
gem 'open_uri_redirections'
gem 'dotenv-rails'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', '~> 0.4.0'
end

group :development do
  gem 'pry-remote'
  gem 'letter_opener'
  gem 'term-ansicolor'
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'

  # Adds some nice rake tasks for generating migrations
  gem 'lol_dba'
end

group :development, :test do
  gem 'lograge'
  gem 'bundler-audit'

  # Spring speeds up development by keeping your application running
  # in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-rails', require: false
  gem 'terminal-notifier-guard', '~> 1.7.0'
  gem 'byebug'
end

group :test do
  gem 'database_cleaner'
  gem 'rspec-rails'
  gem 'pry'
  gem 'poltergeist'
  gem 'faker'
  gem 'factory_bot_rails'
  gem 'coveralls', '~> 0.8.21'
  gem 'vcr'
  gem 'webmock'
  gem 'timecop'
  gem 'foreman'
  # Rails 5 has pulled out 'assigns' - this puts it back
  gem 'rails-controller-testing'
end

group :production do
  gem 'rails_12factor'
  gem 'puma'
end
