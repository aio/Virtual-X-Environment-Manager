class CreatePrivileges < ActiveRecord::Migration
  def self.up
    create_table :privileges do |t|
      t.string :name
      t.string :resource_type
      t.integer :resource_id
      t.boolean :readable
      t.boolean :writable
      t.boolean :executable
      t.boolean :deletable
      t.timestamps
    end
  end

  def self.down
    drop_table :privileges
  end
end
