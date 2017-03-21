class TemporarilyRenameRestrictedColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :datasets, :restricted, :deprecated_restricted
  end
end
