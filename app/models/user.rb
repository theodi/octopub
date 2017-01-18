class User < ActiveRecord::Base

  has_many :datasets

  before_create :generate_api_key

  def self.refresh_datasets id, channel_id = nil
    user = User.find id
    user.send(:get_user_repos)
    Pusher[channel_id].trigger("refreshed", {}) if channel_id
  end

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

  def org_datasets
    Dataset.where(id: org_dataset_ids)
  end

  def all_datasets
    Dataset.where(id: all_dataset_ids) || []
  end

  def all_dataset_ids
    org_dataset_ids.concat(dataset_ids).map { |id| id.to_i }
  end

  private

    def get_user_repos
      self.update_column(:org_dataset_ids, user_repos)
    end

    def user_repos
      octokit_client.auto_paginate = true
      repos = octokit_client.repos.map do |r|
        Dataset.where(full_name: r.full_name).pluck(:id)
      end
      repos.compact
    end

    def generate_api_key
      self.api_key = SecureRandom.hex(10)
    end

end
