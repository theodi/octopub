class MigrateRestrictedFlagFromDataset < ActiveRecord::Migration[5.0]
  def up
    skip_callback_if_exists(Dataset, :update, :after, :update_dataset_in_github)
    skip_callback_if_exists(Dataset, :update, :after, :update_in_github) 

    Dataset.all.each do |dataset|
      if dataset.deprecated_restricted
        dataset.update(publishing_method: :github_private)
      end
    end
  end

  def down
  end

  def skip_callback_if_exists(thing, name, kind, filter)
    if any_callbacks?(thing._update_callbacks, name, kind, filter)
      thing.skip_callback(name, kind, filter)
    end
  end

  def any_callbacks?(callbacks, name, kind, filter)
    callbacks.select { |cb| cb.name == name && cb.kind == kind && cb.filter == filter }.any?
  end
end
