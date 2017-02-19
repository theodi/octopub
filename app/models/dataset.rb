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

require 'git_data'

class Dataset < ApplicationRecord

  belongs_to :user
  has_many :dataset_files

  after_create :create_repo_and_populate, :set_owner_avatar, :publish_public_views, :send_success_email, :send_tweet_notification
  after_update :update_dataset_in_github, :make_repo_public_if_appropriate, :publish_public_views
  after_destroy :delete_in_github

  validate :check_repo, on: :create
  validates_associated :dataset_files

  def report_status(channel_id)
    logger.info "report_status #{channel_id}"
    if valid?
      Pusher[channel_id].trigger('dataset_created', self) if channel_id
      logger.info "Valid so now do the save and trigger the after creates"
      save
    else
      messages = errors.full_messages
      dataset_files.each do |file|
        unless file.valid?
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

  # def add_file_to_repo(filename, file)
  #   @repo.add_file(filename, file)
  # end

  # def update_file_in_repo(filename, file)
  #   @repo.update_file(filename, file)
  # end

  def update_file_in_repo(filename, file)
    JekyllService.new(self, @repo).update_file_in_repo(filename, file)
  end

  def delete_file_from_repo(filename)
    @repo.delete_file(filename)
  end

  def path(filename, folder = "")
    File.join([folder,filename].reject { |n| n.blank? })
  end

  def create_data_files
    JekyllService.new(self, @repo).create_data_files
  end

  # def create_data_files
  #   logger.info "Create data files and add to github"
  #   dataset_files.each { |d| d.add_to_github }
  #   logger.info "Create datapackage and add to repo"
  #   create_json_datapackage_and_add_to_repo

  #   dataset_files.each do |dataset_file|
  #     dataset_file.validate
  #     if dataset_file.dataset_file_schema
  #       add_file_to_repo("#{dataset_file.dataset_file_schema.name.downcase.parameterize}.schema.json", dataset_file.dataset_file_schema.schema)
  #       # For ref, does a send as it's a private method
  #       dataset_file.send(:create_json_api_files, dataset_file.dataset_file_schema.parsed_schema)
  #     end
  #   end

  # end

  # def create_jekyll_files
  #   dataset_files.each { |d| d.add_jekyll_to_github }
  #   add_file_to_repo("index.html", File.open(File.join(Rails.root, "extra", "html", "index.html")).read)
  #   add_file_to_repo("_config.yml", config)
  #   add_file_to_repo("css/style.css", File.open(File.join(Rails.root, "extra", "stylesheets", "style.css")).read)
  #   add_file_to_repo("_layouts/default.html", File.open(File.join(Rails.root, "extra", "html", "default.html")).read)
  #   add_file_to_repo("_layouts/resource.html", File.open(File.join(Rails.root, "extra", "html", "resource.html")).read)
  #   add_file_to_repo("_layouts/api-item.html", File.open(File.join(Rails.root, "extra", "html", "api-item.html")).read)
  #   add_file_to_repo("_layouts/api-list.html", File.open(File.join(Rails.root, "extra", "html", "api-list.html")).read)
  #   add_file_to_repo("_includes/data_table.html", File.open(File.join(Rails.root, "extra", "html", "data_table.html")).read)
  #   add_file_to_repo("js/papaparse.min.js", File.open(File.join(Rails.root, "extra", "js", "papaparse.min.js")).read)

  #   dataset_files.each do |f|
  #     # For ref, does a send as it's a private method
  #     f.send(:create_json_jekyll_files, f.dataset_file_schema.parsed_schema) unless f.dataset_file_schema.nil?
  #   end
  # end

  # def create_json_datapackage_and_add_to_repo
  #   add_file_to_repo("datapackage.json", create_json_datapackage)
  # end

  # def update_datapackage
  #   update_file_in_repo("datapackage.json", create_json_datapackage)
  # end

  def update_datapackage
    JekyllService.new(self, @repo).update_datapackage
  end

  # def create_json_datapackage
  #   datapackage = {}

  #   datapackage["name"] = name.downcase.parameterize
  #   datapackage["title"] = name
  #   datapackage["description"] = description
  #   datapackage["licenses"] = [{
  #     "url"   => license_details.url,
  #     "title" => license_details.title
  #   }]
  #   datapackage["publishers"] = [{
  #     "name"   => publisher_name,
  #     "web" => publisher_url
  #   }]

  #   datapackage["resources"] = []

  #   dataset_files.each do |file|
  #     datapackage["resources"] << {
  #       "name" => file.title,
  #       "mediatype" => 'text/csv',
  #       "description" => file.description,
  #       "path" => "data/#{file.filename}",
  #       "schema" => json_schema_for_datapackage(file.dataset_file_schema)
  #     }.delete_if { |k,v| v.nil? }
  #   end

  #   datapackage.to_json
  # end

  # def json_schema_for_datapackage(dataset_file_schema)
  #   return if dataset_file_schema.nil? || dataset_file_schema.is_schema_otw?
  #   schema_hash = JSON.parse(dataset_file_schema.schema)
  #   schema_hash["name"] = dataset_file_schema.name
  #   schema_hash["description"] = dataset_file_schema.description
  #   schema_hash
  # end

  def create_json_datapackage
    JekyllService.new(self, @repo).create_json_datapackage
  end

  def config
    {
      "data_dir" => '.',
      "update_frequency" => frequency,
      "permalink" => 'pretty'
    }.to_yaml
  end

  # def license_details
  #   Odlifier::License.define(license)
  # end

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

  def fetch_repo(client = user.octokit_client)
    begin
      @repo = GitData.find(repo_owner, self.name, client: client)
      # This is in for backwards compatibility at the moment required for API

    rescue Octokit::NotFound
      @repo = nil
    end
  end

  private

    def create_repo_and_populate
      p "in create_repo_and_populate"
      @repo = RepoService.create_repo(repo_owner, name, restricted, user)
      self.update_columns(url: @repo.html_url, repo: @repo.name, full_name: @repo.full_name)
      p "Now updated with github details - call commit!"
      @jekyll_service = JekyllService.new(self, @repo)
      @jekyll_service.add_files_to_repo_and_push_to_github
    end

    def add_files_to_repo_and_push_to_github
      JekyllService.new(self, @repo).add_files_to_repo_and_push_to_github
    #   push_to_github
    end

    def update_dataset_in_github
      JekyllService.new(self, @repo).update_dataset_in_github
    end

    def make_repo_public_if_appropriate
      # Should the repo be made public?
      if restricted_changed? && restricted == false
        @repo.make_public
      end
    end

    def delete_in_github
      @repo.delete if @repo
    end

    def push_to_github
      JekyllService.new(self, @repo).push_to_github
    #   logger.info "In push_to_github method, @repo.save - @repo is a GitData object"
    #   @repo.save
    end

    def check_repo
      repo_name = "#{repo_owner}/#{name.parameterize}"
      if user.octokit_client.repository?(repo_name)
        errors.add :repository_name, 'already exists'
      end
    end

    def set_owner_avatar
      if owner.blank?
        update_column :owner_avatar, user.avatar
      else
        update_column :owner_avatar, Rails.configuration.octopub_admin.organization(owner).avatar_url
      end
    end

    def send_success_email
      DatasetMailer.success(self).deliver
    end

    def send_tweet_notification
      if ENV["TWITTER_CONSUMER_KEY"] && user.twitter_handle
        twitter_client = Twitter::REST::Client.new do |config|
          config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
          config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
          config.access_token        = ENV["TWITTER_TOKEN"]
          config.access_token_secret = ENV["TWITTER_SECRET"]
        end
        twitter_client.update("@#{user.twitter_handle} your dataset \"#{self.name}\" is now published at #{self.gh_pages_url}")
      end
    end

    def publish_public_views
      return if restricted
      if id_changed? || restricted_changed?
        # This is either a new record or has just been made public
        create_public_views
      end
      # updates to existing public repos are handled in #update_in_github
    end

    def create_jekyll_files
      JekyllService.new(self, @repo).create_jekyll_files
    end

    def create_public_views
      create_jekyll_files
      push_to_github
      wait_for_gh_pages_build
      create_certificate
    end

    def wait_for_gh_pages_build(delay = 5)
      sleep(delay) while !gh_pages_built?
    end

    def gh_pages_built?
      user.octokit_client.pages(full_name).status == "built"
    end

    def create_certificate
      cert = CertificateFactory::Certificate.new gh_pages_url

      gen = cert.generate

      if gen[:success] == 'pending'
        result = cert.result
        add_certificate_url(result[:certificate_url])
      end
    end

    def add_certificate_url(url)
      return if url.nil?

      url = url.gsub('.json', '')
      update_column(:certificate_url, url)

      config = {
        "data_source" => ".",
        "update_frequency" => frequency,
        "certificate_url" => "#{certificate_url}/badge.js"
      }.to_yaml

      fetch_repo(user.octokit_client)
      update_file_in_repo('_config.yml', config)
      push_to_github
    end

end
