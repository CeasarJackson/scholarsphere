class AddLinkedinToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :linkedin_handle, :string
  end
end
