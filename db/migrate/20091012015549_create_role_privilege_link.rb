class CreateRolePrivilegeLink < ActiveRecord::Migration
  def self.up
    create_table :role_privilege_link do |t|
      t.references :role
      t.references :privilege
      t.timestamps
    end
  end

  def self.down
    drop_table :role_privilege_link
  end
end
