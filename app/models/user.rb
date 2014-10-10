class User < ActiveRecord::Base

  has_many :datasets

  def self.find_for_github_oauth(auth)
    user = User.find_or_create_by(provider: auth["provider"], uid: auth["uid"])
    user.update_attributes(
                           name: auth["info"]["nickname"],
                           email: auth["info"]["email"],
                           token: auth["credentials"]["token"]
                          )
    user
  end

  def octokit_client
    @client ||= Octokit::Client.new :access_token => token
    @client
  end

  def refresh_datasets
    datasets.all.each do |dataset|
      begin
        octokit_client.repository(dataset.full_name)
      rescue Octokit::NotFound
        dataset.delete
      end
    end
  end

end
