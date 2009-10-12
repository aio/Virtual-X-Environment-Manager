class Privilege < ActiveRecord::Base
  validates_length_of :name, :within => 3..40
  validates_presence_of :name, :resource_type, :resource_id
  validates_uniqueness_of :name
  
  @@resource_types = ['EVERYTHING', 
                      'VM',
                      'NODE',
                      'STORAGE'
                     ]
  def self.resource_types
    @@resource_types
  end
end
