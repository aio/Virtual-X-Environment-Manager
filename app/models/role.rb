class Role < ActiveRecord::Base
  has_and_belongs_to_many :privileges, 
  :join_table => 'role_privilege_link', 
  :association_foreign_key => 'privilege_id', 
  :foreign_key => 'role_id'
end
