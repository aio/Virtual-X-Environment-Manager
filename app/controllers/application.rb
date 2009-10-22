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

  def validate_request_required
    valid = false
    
    resource = params[:controller]
    action = params[:action] ? params[:action].to_sym : nil
    id = params[:id] ? params[:id].to_i : 0
    
    catch :found do
      session[:user].roles.each { |role|
        role.privileges.each { |privilege|
          
          #debug info
          logger.info "resource=#{resource}"
          logger.info "id=#{id}"
          logger.info "action=#{action}"
          logger.info "privilege.resource_type=#{privilege.resource_type}"
          logger.info "privilege.resource_id=#{privilege.resource_id}"
          logger.info "privilege.valid_request? resource,id,action=#{privilege.valid_request? resource,id,action}"
          
          if privilege.valid_request?(resource, id, action)
            valid = true
            throw :found 
          end
        }
      }
    end
    
    return true if valid
    
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
