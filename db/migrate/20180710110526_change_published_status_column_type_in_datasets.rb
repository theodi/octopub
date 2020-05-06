class ChangePublishedStatusColumnTypeInDatasets < ActiveRecord::Migration[5.0]
	def up
	  change_column :datasets, :published_status, "text using case when published_status then 'published' else 'unpublished' end", :default => 'unpublished'
	end

	def down
	  change_column :datasets, :published_status, "boolean using published_status = 'published'"
	end
end
