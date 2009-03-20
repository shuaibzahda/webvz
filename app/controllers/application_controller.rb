# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'bb94fe1aac26787e53a52ea7be7335a1'

#private methods
#
private
  
	def authorize
    		unless User.find_by_id(session[:user_id])
      			flash[:notice] = "Please log in"
      			redirect_to(:controller => :login , :action => :sign_in)
    		end
	end

	def authorize_admin
		if session[:permission] == "admin"
			return true
		else
			flash[:notice] = "You do not have administration priviliges to access this fucntion."
			redirect_to(:controller => :menu)
			return false
		end
	end	
	
	def authorize_client
		if session[:permission] == "client"
                        return true
                else
                        flash[:notice] = "You do not have administration priviliges to access this fucntion."
                        redirect_to(:controller => :menu)
                        return false
                end

	end

	def is_vz_running
                @output = `uname -r`
                if File.exist?("/proc/vz")
		#if @output.include?("stab") || @output.include?("gc") || @output.include?("ovz") || @output.include?("openvz")
                        @status = `/etc/init.d/vz status`
                        unless @status.include?("running")
                                flash[:notice] = "VZ service is not running."
                                redirect_to :controller => :openvz, :action => :vz_status
                        end
                else
                        flash[:notice] = "The kernel does not support OpenVZ."
                        redirect_to :controller => :menu, :action => :index
                end
        end
 
	def get_vps_id
                @vps_id = params[:vps_id]
        end

	def get_conf_files_names
		all_conf = `ls /etc/vz/conf/*.conf-sample`
                names = all_conf.split("\n")
                @conf_names = []
                for file in names
                        n = file.split("ve-")
                        name = n[1].split(".conf-sample")
                        @conf_names << name[0]
                end
		return @conf_names
	end

	def write_conf(name, conf_file)
		cnf = Vps.new
		cnf.write_to_conf_file(name, conf_file)
		flash[:notice] = "#{name} configuration file was created/modified successfully."
		redirect_to :controller => :configfile, :action => :list_conf_file
	end

	def extract_vps_values(i, k)
                array = i.split("\n")
		array2 = k.split("\n") # to get the name of the container
		@rows = []
		@names = []

		#extract the names of the containers
		for row in array2	
			parts = row.split(" ")
			@names << parts[4]
		end
		#extract other information like id, ip, hostname, etc
		for row in array
			r = row.split(" ")
			#extract name of distro for the logo   
                        r  << distro_name(r[0])
			@rows << r
                end
                @rows
	end
	
        def distro_name(vps_id)
                first_line = ""
                file = File.open("/vz/private/#{vps_id}/etc/issue")
                file.each_line {|line| first_line = line; break }
                file.close
                x = first_line.split(" ")
                dist_name = x[0]
        end

end
