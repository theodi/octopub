# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  provider        :string
#  uid             :string
#  email           :string
#  created_at      :datetime
#  updated_at      :datetime
#  name            :string
#  token           :string
#  api_key         :string
#  org_dataset_ids :text             default([]), is an Array
#  twitter_handle  :string
#  role            :integer          default("publisher"), not null
#

class User < ApplicationRecord

  enum role: [:publisher, :superuser, :admin]

  has_many :datasets
  has_many :dataset_file_schemas
  has_and_belongs_to_many :allocated_dataset_file_schemas, class_name: 'DatasetFileSchema', join_table: :allocated_dataset_file_schemas_users

  before_validation :generate_api_key, on: :create

  def self.refresh_datasets id, channel_id = nil
    user = User.find id
    user.send(:get_user_repos)
    Pusher[channel_id].trigger("refreshed", {}) if channel_id
  end

  def self.find_for_github_oauth(auth)
    user = User.where(provider: auth["provider"], uid: auth["uid"]).first_or_create
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
    Dataset.where(id: all_dataset_ids).order(:id) || []
  end

  def all_dataset_ids
    org_dataset_ids.concat(dataset_ids).map { |id| id.to_i }
  end

  # def allocated_dataset_file_schemas
  #   Array.new
  # end

  private

    def get_user_repos
      self.update_column(:org_dataset_ids, user_repos)
    end

    def user_repos
      octokit_client.auto_paginate = true
      repos = octokit_client.repos.map do |r|
        Dataset.find_by_full_name(r.full_name).try(:id)
      end
      repos.compact
    end

    def generate_api_key
      self.api_key = SecureRandom.hex(10)
    end

end
