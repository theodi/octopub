Rails.application.config.octopub_admin = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
