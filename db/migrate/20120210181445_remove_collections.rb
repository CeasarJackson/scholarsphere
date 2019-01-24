class RemoveCollections < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :collections
  end

  def self.down
    create_table :collections do |t|
      t.string :name
      t.integer :user_id
      t.timestamps
    end
  end
end
