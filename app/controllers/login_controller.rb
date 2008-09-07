class LoginController < ApplicationController
  before_filter :authorize, :except => :sign_in
  def logout
    session[:user_name] = nil
    session[:user_id] = nil
    session[:name] = nil
    session[:permission] = nil
    flash[:notice] = "You are logged out"
    redirect_to :action => :sign_in
  end
  
  def sign_in
    session[:user_id] = nil
    session[:permission] = nil
    if request.post?
      user = User.authunticate(params[:username], params[:password])
      if user && user.activated == 'yes'
        session[:user_id] = user.id
        session[:user_name] = user.username
        session[:name] = user.name
	session[:permission] = user.authority
        flash[:notice] = "You are logged in"
        redirect_to :controller => :menu, :action => :index
      else 
        flash[:notice] = "Invalid username/password"
      end
    end
  end

end
