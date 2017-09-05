namespace :links do

  desc "flag datasets that have broken links"
  task broken: :environment do # TODO logic into dataset model as new method
    Dataset.check_urls
  end
end