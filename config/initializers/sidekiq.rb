if Rails.env.development?
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end

# Old behaviour, we should look at moving to ActiveJob instead probably to get this
# https://github.com/mperham/sidekiq/blob/master/5.0-Upgrade.md
Sidekiq::Extensions.enable_delay!

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDISTOGO_URL'] || "redis://localhost:6379" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDISTOGO_URL'] || "redis://localhost:6379" }
end
