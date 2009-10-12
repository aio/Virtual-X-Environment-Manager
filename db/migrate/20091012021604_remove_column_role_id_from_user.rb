class RemoveColumnRoleIdFromUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :role_id
  end

  def self.down
  end
end
