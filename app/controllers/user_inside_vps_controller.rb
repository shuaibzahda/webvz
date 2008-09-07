class UserInsideVpsController < ApplicationController
	
	before_filter :authorize
	before_filter :authorize_client
	before_filter :authorized_logged_in
	before_filter :get_vps_id
	
	def services
                output = `vzctl exec #{@vps_id} ls /etc/init.d/`
                @all_services = output.split("\n")
        end
	
	def monitor_resources
                out = `cat /proc/bc/#{@vps_id}/resources`
                @ubc = out.split("\n")
        end

        def edit_nameserver
                output = ""
                output += `vzctl set #{@vps_id} --nameserver #{@conf[:NAMESERVER]} --save`
                write_conf(output, 'basic_net')
        end

        def edit_hostname
                output = ""
                output += `vzctl set #{@vps_id} --hostname #{@conf[:HOSTNAME]} --save`
                write_conf(output, 'basic_net')
        end

	def view_vps
                i = `vzlist -aH #{@vps_id}`
                k = `vzlist -aHn #{@vps_id}`
                thename = k.split(" ")
                @name = thename[4]
                @line = i.split(" ")
                #extract name of distro
                @line  << distro_name(@line[0])
                @uptime = `vzctl exec #{@vps_id} uptime`
        end
                
	def run_command
        end

        def execute_cmd
                @cmd = params[:command][:line]
                @output = `vzctl exec #{@vps_id} #{@cmd}`
        end

        def running_processes
                out=''
                File.popen("vzctl exec #{@vps_id} ps aux"){|f|f.gets;out=f.read}
                @procs = out.split("\n")
        end

	def start_service
                name = params[:ser_name]
                out = `vzctl exec #{@vps_id} /etc/init.d/#{name} start`
                flash[:notice] = out
                redirect_to :action => :services, :vps_id => @vps_id, :id => session[:user_id]
        end

        def stop_service
                name = params[:ser_name]
                out = `vzctl exec #{@vps_id} /etc/init.d/#{name} stop`
                flash[:notice] = out
                redirect_to :action => :services, :vps_id => @vps_id, :id => session[:user_id]
        end

        def restart_service
                name = params[:ser_name]
                out = `vzctl exec #{@vps_id} /etc/init.d/#{name} restart`
                flash[:notice] = out
                redirect_to :action => :services, :vps_id => @vps_id, :id => session[:user_id]
        end

        private
        def authorized_logged_in
		#check that the user is not typing on the browser ids of containers and ids of users that are not his/her
		vps = Vps.find_by_cnt_id(params[:vps_id])
		if session[:user_id].to_i != vps.user_id.to_i || session[:user_id].to_i != params[:id].to_i
                        flash[:notice] = "You have no privileges to access this area"
                        redirect_to :controller => :menu
		end
        end

	def get_conf
                @conf = params[:conf]
        end
end
