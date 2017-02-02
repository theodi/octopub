class RenamePrivateToRestrictedInDatasets < ActiveRecord::Migration[5.0]
  def change
    rename_column :datasets, :private, :restricted
  end
end
