class Privilege < ActiveRecord::Base
  validates_length_of :name, :within => 3..40
  validates_presence_of :name, :resource_type, :resource_id
  validates_uniqueness_of :name
  
  @@resource_types = {
                      '*' => 'Everything (Only for admin)',
                      '/' => 'Index page', 
                      'virtual_machines' => 'Virtual Machine',
                      'host_nodes' => 'Standalone server of node of cluster',
                      'storages' => 'Storage Pool',
                      'users' => 'Users',
                      'roles' => 'Roles',
                      'privileges' => 'Privileges'
                     }
  @@resource_actions = {
                         :readable => [:index, :list, :show],
                         :writable => [:edit, :update, :vnc_client, :qm_monitor],
                         :executable => [:start, :stop],
                         :deletable => [:destroy]
                       }
  def self.resource_types
    @@resource_types
  end
  
  def self.resource_actions
    @@resource_actions
  end
  
  def valid_request?(requested_resource, requested_id, requested_action)
    # for admin passthrough
    return true if resource_type == '*' and readable and writable and executable and deletable
    
    if requested_resource == resource_type and requested_id == resource_id
      action_type = nil
      @@resource_actions.keys.each { |key|
        if @@resource_actions[key].include? requested_action
          action_type = key
          break 
        end
      }
      case action_type
      when :readable
        return readable
      when :writable
        return writable
      when :executable
        return executable
      when :deletable
        return deletable
      else
        return false
      end
    else
      return false
    end
  end

end
