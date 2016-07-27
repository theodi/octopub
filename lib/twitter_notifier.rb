class TwitterNotifier
  def self.client
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_TOKEN"]
      config.access_token_secret = ENV["TWITTER_SECRET"]
    end
  end

  def self.success(dataset, user)
    self.client.update("Hi @#{user.twitter_handle}, your dataset \"#{dataset.name}\" is now published at #{dataset.gh_pages_url} #octopub http://octopub.io")
  end
end
