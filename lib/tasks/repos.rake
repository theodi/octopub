namespace :repos do
  desc "Clean up deleted repos"
  task cleanup: :environment do
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    Dataset.all.each do |dataset|
      begin
        client.repository(dataset.full_name)
      rescue Octokit::NotFound
        puts "Dataset #{dataset.name} no longer exists"
        dataset.delete
      rescue Octokit::InvalidRepository
      end
    end
  end
end
