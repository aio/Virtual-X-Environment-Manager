class Role < ActiveRecord::Base
  validates_length_of :name, :within => 3..40
  validates_length_of :description, :within => 0..80
  validates_presence_of :name
  validates_uniqueness_of :name
  
  has_and_belongs_to_many :privileges, 
                          :join_table => 'role_privilege_link', 
                          :association_foreign_key => 'privilege_id', 
                          :foreign_key => 'role_id'


end
