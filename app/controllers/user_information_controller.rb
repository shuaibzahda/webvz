class UserInformationController < ApplicationController

	before_filter :authorize_client
	before_filter :authorized_logged_in

	def view_user_by_user
		@user = User.find(params[:id])
	end

	def edit
		@user = User.find(params[:id])
	end

	def update
		@user = User.find(params[:id])
    		if @user.update_attributes(params[:user])
      			flash[:notice] = 'User was successfully updated.'
      			redirect_to :controller => :user_information, :action => 'view_user_by_user', :id => @user
    		else
      			render :action => 'edit'
    		end
	end
	
	def change_password
        	@user = User.find(params[:id])
  	end

  	def update_password
           if params[:password][:p1] == params[:password][:p2]
               	@user = User.find(params[:id])
		current_pass = User.encrypt_password(params[:password][:current])
	 	if current_pass == @user.password 
			new_pass = User.encrypt_password(params[:password][:p2])
                	@user.password = new_pass
                	if @user.update_attributes(params[:user])
                        	flash[:notice] = "Password has changed successfully."
                        	redirect_to :action => :view_user_by_user, :id => params[:id]
                	end
		else
			flash[:notice] = "Current Password is wrong. Make sure you do not mistype it."
                redirect_to :action => :change_password, :id => params[:id]
		end
           else
                flash[:notice] = "Passwords did not match. Make sure you do not mistype them."
                redirect_to :action => :change_password, :id => params[:id]
           end
	end
	
	private

	def authorized_logged_in
		if session[:user_id].to_i != params[:id].to_i
			flash[:notice] = "You have no privileges to access this area"
			redirect_to :controller => :menu
		end
	end

end
