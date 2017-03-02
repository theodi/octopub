class InferredDatasetFileSchema
  include ActiveModel::Model

  attr_accessor :user_id, :name, :description, :csv_url

  validates :user_id, presence: true
  validates :name, presence: true
  validates :csv_url, presence: true
end
