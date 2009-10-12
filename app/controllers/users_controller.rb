class UsersController < ApplicationController
  before_filter :admin_required, :only => ['list', 'new','create', 'destroy', 'edit', 'update', 'signup', 'reset_password']

  def signup
    @user = User.new
    if request.post?
      @user = User.new(params[:user]) 
      if @user.save
        #session[:user] = User.authenticate(@user.login, @user.password)
        flash[:message] = "注册成功"
        redirect_to :action => "list"
      else
        flash[:warning] = "注册失败"
      end
    end
  end
  
  def list
    @users = User.all
    flash[:message] = ''
  end
  
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to :action => "list"
  end
  
  def login
    if request.post?
      if session[:user] = User.authenticate(params[:user][:login], params[:user][:password])
        flash[:message]  = "登录成功"
        redirect_to_stored
      else
        flash[:warning] = "登录失败"
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
        flash[:message]="#{@user.login}密码已经成功更新了！"
      end
    end
    
  end

  def change_password
    @user=session[:user]
    if request.post?
      @user.update_attributes(:password=>params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
      if @user.save
        flash[:message]="密码已经成功更新了！"
      end
    end
    
  end
end
