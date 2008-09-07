class UserController < ApplicationController
  before_filter :authorize
  before_filter :authorize_admin, :expect => [:view_user_by_user]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    #@user_pages, @users = paginate :users, :per_page => 10
    @users = User.find(:all)
  end
  
  def activated
    @users = User.find(:all, :conditions => 'activated = "yes"')
    render :action => :list
  end

  def deactivated
    @users = User.find(:all, :conditions => 'activated = "no"')
    render :action => :list
  end
  
  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @user.password = User.encrypt_password(params[:user][:password])
    if @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user
    else
      render :action => 'edit'
    end
  end

  def change_password
	 @user = User.find(params[:id])
  end

  def update_password
	if params[:password][:p1] == params[:password][:p2]
		new_pass = User.encrypt_password(params[:password][:p2])
		@user = User.find(params[:id])
		@user.password = new_pass
		if @user.update_attributes(params[:user])
			flash[:notice] = "Password has changed successfully."
			redirect_to :action => :show, :id => params[:id]
		end
	else
		flash[:notice] = "Passwords did not match. Make sure you do not mistype them."
		redirect_to :action => :change_password, :id => params[:id]
	end
  end
end
