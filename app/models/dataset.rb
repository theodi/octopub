# == Schema Information
#
# Table name: datasets
#
#  id                :integer          not null, primary key
#  name              :string
#  url               :string
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#  repo              :string
#  description       :text
#  publisher_name    :string
#  publisher_url     :string
#  license           :string
#  frequency         :string
#  datapackage_sha   :text
#  owner             :string
#  owner_avatar      :string
#  build_status      :string
#  full_name         :string
#  certificate_url   :string
#  job_id            :string
#  publishing_method :integer          default("github_public"), not null
#  published_status  :text						 default("unpublished")
##TODO does above have to be updated to reflect changes made by migrations?
#

class Dataset < ApplicationRecord
	include Publishable

  enum publishing_method: [:github_public, :github_private, :local_private]

  # Note it is the user who is logged in and creates the dataset
  # It can be owned by someone else
  belongs_to :user
  has_many :dataset_files

  # after_update :update_dataset_in_github, unless: Proc.new { |dataset| dataset.local_private? }
  after_destroy :delete_dataset_in_github, unless: Proc.new { |dataset| dataset.local_private? }

  validate :check_repo, on: :create
  validates_associated :dataset_files

end
