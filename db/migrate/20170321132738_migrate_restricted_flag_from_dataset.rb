class MigrateRestrictedFlagFromDataset < ActiveRecord::Migration[5.0]
  def up
    Dataset.all.each do |dataset|
      if dataset.deprecated_restricted
        dataset.update_columns(publishing_method: :github_private)
      end
    end
  end

  def down
  end
end
