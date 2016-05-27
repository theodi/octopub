class User < ActiveRecord::Base

  has_many :datasets

  before_create :generate_api_key

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

  def github_username
    name.parameterize
  end

  def github_user
    @github_user ||= Rails.configuration.octopub_admin.user(github_username)
  end

  def avatar
    github_user.avatar_url
  end

  def organizations
    @organizations ||= octokit_client.org_memberships.select { |m| m[:role] == 'admin' }
  end

  private

    def generate_api_key
      self.api_key = SecureRandom.hex(10)
    end

end
