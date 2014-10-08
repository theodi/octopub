class ChangeDescriptionToText < ActiveRecord::Migration
  def change
    change_column :datasets, :description, :text
  end
end
