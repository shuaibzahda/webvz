class UserContainersController < ApplicationController

        before_filter :authorize
        before_filter :get_vps_id
	before_filter :authorized_logged_in
        before_filter :authorize_client

	def list_vps
		@status = params[:status]
		@user = User.find_by_id(params[:id])
		ids = @user.vpss.map {|vps| [vps.cnt_id]}
                #@status ||= "all"
                if @status == "running"
#this is a bug, filter the running one only
                        i = `vzlist -H #{ids.join(" ")}`
                        k = `vzlist -Hn #{ids.join(" ")}`
                elsif @status == "stopped"
                        i = `vzlist -SH #{ids.join(" ")}`
                        k = `vzlist -SHn #{ids.join(" ")}`
                else
                        i = `vzlist -aH #{ids.join(" ")}`
                        k = `vzlist -aHn #{ids.join(" ")}`
                        @status = ""
                end
		
                @rows = extract_vps_values(i, k)
	end

	def start_vps
                msg = `vzctl start #{@vps_id}`
                redirect_msg(@vps_id, "started\n" + msg)
        end

        def restart_vps
                msg = `vzctl restart #{@vps_id}`
                redirect_msg(@vps_id, "restarted\n" + msg)
        end

        def stop_vps
                msg = `vzctl stop #{@vps_id}`
		redirect_msg(@vps_id, "stopped\n"+ msg)
        end

	private
	def redirect_msg (vps_id, msg)
                flash[:notice] = "Container #{vps_id} #{msg}"
                redirect_to :action => :list_vps, :id => session[:user_id]
        end

	def authorized_logged_in
		if session[:user_id].to_i != params[:id].to_i
			flash[:notice] = "You have no privileges to access other's accounts"
			redirect_to :controller => :menu
		end 
	end
end
