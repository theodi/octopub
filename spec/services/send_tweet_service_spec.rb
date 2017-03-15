require 'rails_helper'

describe SendTweetService do

    before(:all) do
      @tweeter = create(:user, twitter_handle: "bob")
      @nontweeter = create(:user, twitter_handle: nil)
    end

    before(:each) do
      allow_any_instance_of(Octokit::Client).to receive(:repository?) { false }
    end

    context "with twitter creds" do

      before(:all) do
        ENV["TWITTER_CONSUMER_KEY"] = "test"
        ENV["TWITTER_CONSUMER_SECRET"] = "test"
        ENV["TWITTER_TOKEN"] = "test"
        ENV["TWITTER_SECRET"] = "test"
      end

      it "sends twitter notification to twitter users" do
        expect_any_instance_of(Twitter::REST::Client).to receive(:update).with("@bob your dataset \"My Awesome Dataset\" is now published at http://#{@tweeter.github_username}.github.io/").once
        dataset = build(:dataset, user: @tweeter)

        SendTweetService.new(dataset).perform
      end

      it "a twitter user can tweet" do
        dataset = build(:dataset, user: @tweeter)
        expect(SendTweetService.new(dataset).can_tweet?).to be true
      end

      it "a twitter user can't tweet" do
        dataset = build(:dataset, user: @nontweeter)
        expect(SendTweetService.new(dataset).can_tweet?).to be false
      end

      it "doesn't send twitter notification to non twitter users" do
        expect_any_instance_of(Twitter::REST::Client).to_not receive(:update)
        dataset = build(:dataset, user: @nontweeter)

        SendTweetService.new(dataset).perform
      end
    end

    context "without twitter creds" do

      before(:all) do
        ENV.delete("TWITTER_CONSUMER_KEY")
        ENV.delete("TWITTER_CONSUMER_SECRET")
        ENV.delete("TWITTER_TOKEN")
        ENV.delete("TWITTER_SECRET")
      end

      it "a twitter user can't tweet if no environment vars" do
        dataset = build(:dataset, user: @tweeter)
        expect(SendTweetService.new(dataset).can_tweet?).to be false
      end

      it "doesn't send twitter notification" do
        expect_any_instance_of(Twitter::REST::Client).to_not receive(:update)
        dataset = create(:dataset, user: @tweeter)
      end
    end
  end
