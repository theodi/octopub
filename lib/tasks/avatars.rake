namespace :avatars do
  desc "Refresh avatars"
  task refresh: :environment do
    Dataset.all.each { |d| d.send(:set_owner_avatar) }
  end
end
