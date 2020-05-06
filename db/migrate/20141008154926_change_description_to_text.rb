class ChangeDescriptionToText < ActiveRecord::Migration[4.2]
  def change
    change_column :datasets, :description, :text
  end
end
