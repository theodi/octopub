namespace :repos do
  desc "Clean up deleted repos"
  task cleanup: :environment do
    User.all.each do |u|
      u.refresh_datasets
    end
  end
end
