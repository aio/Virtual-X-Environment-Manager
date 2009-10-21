# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'c54c8c32fe4dba668d43baa61ea867a3'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  def redirect_to_user_home
      redirect_to :controller=>'virtual_machines', :action=>'index'
  end
  
  def login_required
    if session[:user]
      return true
    end
    flash[:warning]='Please login to continue'
    session[:return_to]=request.request_uri
    redirect_to :controller => "users", :action => "login"
    return false
  end

  def request_parse
    arr = request.request_uri.split('/')
    method = request.method
    resource = id = action = nil
    case arr.size
    when 0
      resource = '/'
      id = 0
      action = :index if method = :get      
    when 2
      resource = arr[1]
      id = 0
      action = :list if method = :get
    when 3
      resource = arr[1]
      case method
      when :get
        action = :show 
      when :post
        action = :delete
      when :put
        action = :update
      else
        action = nil
      end
      id = arr[2]
    when 4
      resource = arr[1]
      id = arr[3].to_i
      action = arr[2] if method = :get
    else
      logger.info "Invalid URI: #{uri}"
    end
    return resource, id, action
  end

  def request_matches_privilege?(privilege)
    # If it's an administrator privilege, return true directly
    return true if privilege.resource_type == '/' and privilege.readable and privilege.writable and privilege.executable and privilege.deletable
   
    resource, id, action = request_parse
    
    logger.info "resource=#{resource}"
    logger.info "id=#{id}"
    logger.info "action=#{action}"
    logger.info "privilege.resource_type=#{privilege.resource_type}"
    logger.info "privilege.resource_id=#{privilege.resource_id}"
    logger.info "privilege.valid_action? action=#{privilege.valid_action? action}"
    
    return (privilege.resource_type.include? resource and privilege.resource_id == id and privilege.valid_action? action)
  end

  def validate_request_required
    session[:user].roles.each { |role|
      role.privileges.each {|privilege|
        return true if request_matches_privilege? privilege
      }
    }
    flash[:warning]='Please login to continue'
    session[:return_to]=request.request_uri
    redirect_to :controller => "users", :action => "login"
    return false
  end

  def admin_required
    if session[:user] and session[:user].is_admin?
      return true
    end
    flash[:warning]='Please login to continue'
    session[:return_to]=request.request_uri
    redirect_to :controller => "users", :action => "login"
    return false
  end
  
  def current_user
    session[:user]
  end
  
  def redirect_to_stored
    if return_to = session[:return_to]
      session[:return_to]=nil
      redirect_to return_to
    else
      redirect_to_user_home
    end
  end
  
end
