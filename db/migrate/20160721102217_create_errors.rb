class CreateErrors < ActiveRecord::Migration[4.2]
  def change
    create_table :errors do |t|
      t.string :job_id, null: false
      t.json   :messages
    end
  end
end
