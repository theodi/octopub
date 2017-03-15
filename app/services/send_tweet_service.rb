class SendTweetService

  def initialize(dataset)
    @twitter_handle = dataset.user.twitter_handle
    @dataset_name = dataset.name
    @gh_pages_url = dataset.gh_pages_url
  end

  def perform
    Rails.logger.info "in send_tweet_notification"
    if can_tweet?
      get_twitter_client.update("@#{@twitter_handle} your dataset \"#{@dataset_name}\" is now published at #{@gh_pages_url}")
    end
  end

  def can_tweet?
    ENV["TWITTER_CONSUMER_KEY"].present? && @twitter_handle.present?

  end

  private

  def get_twitter_client
    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_TOKEN"]
      config.access_token_secret = ENV["TWITTER_SECRET"]
    end
  end
end
