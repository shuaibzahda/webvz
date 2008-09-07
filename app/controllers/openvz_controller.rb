class OpenvzController < ApplicationController
	before_filter :authorize
	before_filter :authorize_admin
	
	
	def start_vz
		flash[:notice] = `/etc/init.d/vz start`
		redirect_to :controller => :openvz, :action => :vz_status
	end
	def restart_vz
		flash[:notice] = `/etc/init.d/vz restart`
		redirect_to :controller => :openvz, :action => :vz_status
	end
	def stop_vz
		flash[:notice] = `/etc/init.d/vz stop`
		redirect_to :controller => :openvz, :action => :vz_status
	end
	
	def vz_status
		@status = `/etc/init.d/vz status`	
	end 

end
