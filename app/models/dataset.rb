# == Schema Information
#
# Table name: datasets
#
#  id              :integer          not null, primary key
#  name            :string
#  url             :string
#  user_id         :integer
#  created_at      :datetime
#  updated_at      :datetime
#  repo            :string
#  description     :text
#  publisher_name  :string
#  publisher_url   :string
#  license         :string
#  frequency       :string
#  datapackage_sha :text
#  owner           :string
#  owner_avatar    :string
#  build_status    :string
#  full_name       :string
#  certificate_url :string
#  job_id          :string
#  restricted      :boolean          default(FALSE)
#

class Dataset < ApplicationRecord

  # Note it is the user who is logged in and creates the dataset
  # It can be owned by someone else
  belongs_to :user
  has_many :dataset_files

  after_update :update_dataset_in_github, :make_repo_public_if_appropriate, :publish_public_views
  after_destroy :delete_dataset_in_github

  validate :check_repo, on: :create
  validates_associated :dataset_files

  def report_status(channel_id)
    Rails.logger.info "Dataset: in report_status #{channel_id}"
    Rails.logger.info "Dataset: file count: #{dataset_files.count}"
    if valid?
      Pusher[channel_id].trigger('dataset_created', self) if channel_id
      Rails.logger.info "Dataset: Valid so now do the save and trigger the after creates"
      save
      CreateRepository.perform_async(id)
    else
      Rails.logger.info "Dataset: In valid, so push to pusher"
      messages = errors.full_messages
      dataset_files.each do |file|
        unless file.valid?
          Rails.logger.info "Dataset: Check file is valid"
          (file.errors.messages[:file] || []).each do |message|
            messages << "Your file '#{file.title}' #{message}"
          end
        end
      end
      if channel_id
        Pusher[channel_id].trigger('dataset_failed', messages.uniq)
      else
        Error.create(job_id: self.job_id, messages: messages.uniq)
      end
    end
  end

  def path(filename, folder = "")
    File.join([folder,filename].reject { |n| n.blank? })
  end

  def config
    {
      "data_dir" => '.',
      "update_frequency" => frequency,
      "permalink" => 'pretty'
    }.to_yaml
  end

  def github_url
    "http://github.com/#{full_name}"
  end

  def gh_pages_url
    "http://#{repo_owner}.github.io/#{repo}"
  end

  def full_name
    "#{repo_owner}/#{repo}"
  end

  def repo_owner
    owner.presence || user.github_username
  end

  def actual_repo
    @actual_repo ||= RepoService.fetch_repo(self)
  end

  def complete_publishing
    actual_repo
    set_owner_avatar
    publish_public_views(true)
    send_success_email
    SendTweetService.new(self).perform
  end

  private

    # This is a callback
    def update_dataset_in_github
      Rails.logger.info "in update_dataset_in_github"
      jekyll_service.update_dataset_in_github
    end

    # This is a callback
    def make_repo_public_if_appropriate
      Rails.logger.info "in make_repo_public_if_appropriate"
      # Should the repo be made public?
      if restricted_changed? && restricted == false
        RepoService.new(actual_repo).make_public
      end
    end

    # This is a callback
    def delete_dataset_in_github
      jekyll_service.delete_dataset_in_github
    end

    def check_repo
      Rails.logger.info "in check_repo"
      repo_name = "#{repo_owner}/#{name.parameterize}"
      if user.octokit_client.repository?(repo_name)
        errors.add :repository_name, 'already exists'
      end
    end

    def set_owner_avatar
      Rails.logger.info "in set_owner_avatar"
      if owner.blank?
        update_column :owner_avatar, user.avatar
      else
        update_column :owner_avatar, Rails.configuration.octopub_admin.organization(owner).avatar_url
      end
    end

    def send_success_email
      Rails.logger.info "in send_success_email"
      DatasetMailer.success(self).deliver
    end

    def jekyll_service
      Rails.logger.info "jekyll_service called, so set with #{repo}"
      @jekyll_service ||= JekyllService.new(self, actual_repo)
    end

    # This is a callback
    def publish_public_views(new_record = false)
      Rails.logger.info "in publish_public_views"
      return if restricted
      if new_record || restricted_changed?
        # This is either a new record or has just been made public
        jekyll_service.create_public_views(self)
      end
      # updates to existing public repos are handled in #update_in_github
    end

end
