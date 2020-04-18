class AddUrlInS3ToModels < ActiveRecord::Migration[5.0]
  def change
    add_column :models, :url_in_s3, :text
  end
end
