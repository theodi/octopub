namespace :avatars do
  desc "Refresh avatars"
  task refresh: :environment do
    Dataset.all.each  do |d|
      begin
        d.send(:set_owner_avatar)
      rescue Octokit::NotFound
        Rails.logger.warn "#{d.owner}: #{d.user.name} no longer has a github account"
      end
    end
  end
end
