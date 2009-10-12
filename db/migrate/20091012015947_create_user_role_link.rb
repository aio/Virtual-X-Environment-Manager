class CreateUserRoleLink < ActiveRecord::Migration
  def self.up
    create_table :user_role_link do |t|
      t.references :user
      t.references :role
      t.timestamps
    end
  end

  def self.down
    drop_table :user_role_link
  end
end
