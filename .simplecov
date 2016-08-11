require 'simplecov'
require 'coveralls'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
   add_filter 'app/controllers/grape_swagger_rails/application_controller'
   add_filter 'app/mailers/dataset_mailer'
end
