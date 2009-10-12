class Privilege < ActiveRecord::Base
  @@resource_types = ['EVERYTHING', 
                      'VM',
                      'NODE',
                      '',
                      '',
                     ]
end
