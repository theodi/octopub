class AddUrlDeprecatedFieldToDataset < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :url_deprecated_at, :datetime
  end
end
