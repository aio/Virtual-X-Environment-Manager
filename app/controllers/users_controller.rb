class UsersController < ApplicationController
  before_filter :admin_required, :only => ['index', 'new','create', 'destroy', 'edit', 'update', 'signup', 'reset_password']

  def signup
    @user = User.new
    if request.post?
      @user = User.new(params[:user]) 
      if @user.save
        #session[:user] = User.authenticate(@user.login, @user.password)
        flash[:message] = "Successfully registered!"
        redirect_to :action => "index"
      else
        flash[:warning] = "Registering failed."
      end
    end
  end
  
  def assign_roles
    @user = User.find(params[:id])
    
  end
  
  def update
    id = params[:user] != nil ? params[:user][:id] : params[:id]
    @user = User.find(id)
    @user.updating_roles = true
    @user.roles = []
    params[:user][:role_ids].each {|role_id|
      @user.roles << Role.find(role_id.to_i)
    }
    respond_to do |format|
      if @user.save
        flash[:notice] = 'Roles was successfully assigned.'
        format.html { redirect_to :action => 'index' }
        format.xml  { head :ok }
      else
        format.html { render :action => "assign_roles" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def index
    @users = User.all
    flash[:message] = ''
  end
  
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to :action => "index"
  end
  
  def login
    if request.post?
      if session[:user] = User.authenticate(params[:user][:login], params[:user][:password])
        flash[:message]  = "Logon as #{session[:user].login}"
        redirect_to_stored
      else
        flash[:warning] = "Logon failed"
      end
    end
  end

  def logout
    session[:user] = nil
    session[:return_to] = nil
    #flash[:message] = 'Logged out'
    redirect_to :action => 'login'
  end

  def reset_password
    id = params[:user] != nil ? params[:user][:id] : params[:id]
    @user=User.find(id)
    if request.post?
      @user=User.find(params[:user][:id])      
      @user.update_attributes(:password=>params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
      if @user.save
        flash[:message]="Successfully changed password for #{@user.login}!"
      end
    end
    
  end

  def change_password
    @user=session[:user]
    if request.post?
      @user.update_attributes(:password=>params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
      if @user.save
        flash[:message]="Successfully changed password for #{@user.login}!"
      end
    end
    
  end
end
