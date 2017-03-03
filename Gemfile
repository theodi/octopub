source 'https://rubygems.org'


ruby '2.4.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.2'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'

# Postgres default
gem 'pg'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# Git hosted gems
gem 'csv2json', git: 'https://github.com/theodi/csv2json.git'
gem 'csv2rest', git: 'https://github.com/theodi/csv2rest.git'
gem 'alternate_rails', '~> 5.0.0', git: 'https://github.com/theodi/alternate-rails.git'
gem 'grape-swagger-rails', git: 'https://github.com/pezholio/grape-swagger-rails.git', branch: 'change-layout-test-branch'

gem 'csvlint', git: 'https://github.com/jamesjefferies/csvlint.rb.git', branch: 'ruby-2.4-rails-5.0-compatibility' 
#gem 'csvlint', '~> 0.3.2'

# New way of validating schemas
gem 'jsontableschema'

gem 'omniauth-github'
gem 'dotenv-rails'

# Bootstrap and view stuff
gem 'bootstrap-sass', '~> 3.2.0'
gem 'font-awesome-sass'
gem 'autoprefixer-rails'
gem 'rails-bootstrap-helpers'
gem 'bootstrap-select-rails'
gem 'bootstrap_form'
gem "bootstrap-table-rails"
# For syntax highlighting
gem 'coderay'


# Logging and debug
gem 'awesome_print'

gem 'octokit'
gem 'odlifier'

gem 'git'
gem 'aws-sdk', '~> 2'
gem 'pusher'
gem 'sidekiq'
gem 'open_uri_redirections'
gem 'certificate-factory'
gem 'grape'
gem 'grape-route-helpers'
gem 'grape-swagger'
gem 'grape-swagger-entity'
gem 'redcarpet'
gem 'rouge'
gem 'twitter'

gem 'airbrake-ruby', '1.7.1'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', '~> 0.4.0'
end

group :development do
  gem 'spring-commands-rspec'
  gem 'pry-remote'
  gem 'letter_opener'
  gem 'term-ansicolor'
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-rails', require: false
  gem 'terminal-notifier-guard', '~> 1.6.1'

  # Spring speeds up development by keeping your application running
  # in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :test do
  #gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'rspec-rails'
  gem 'pry'
  gem 'poltergeist'
  gem 'faker'
  gem 'factory_girl_rails'
  gem 'coveralls', git: 'https://github.com/tagliala/coveralls-ruby.git', branch: 'update-simplecov-dependency', require: false
  gem 'vcr'
  gem 'webmock'
  gem 'foreman'
  # Rails 5 has pulled out 'assigns' - this puts it back
  gem 'rails-controller-testing'
end

group :production do
  gem 'rails_12factor'
  gem 'puma'
end
