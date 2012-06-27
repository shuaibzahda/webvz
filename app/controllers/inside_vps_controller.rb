class InsideVpsController < ApplicationController
	before_filter :authorize
	before_filter :authorize_admin
	before_filter :is_vz_running	
	before_filter :get_vps_id
	before_filter :get_conf, :except => [:run_command, :execute_cmd, :view_vps, :booting, :basic_net, :adv_net, :disk_mgt, :cpu_mgt, :memory_mgt, :misc, :monitor_resources, :running_processes, :services, :start_service, :stop_service, :restart_service]
	before_filter :read_conf, :except => [:run_command, :execute_cmd, :view_vps]
	
	def start_service
		name = params[:ser_name]
		out = `vzctl exec #{@vps_id} /etc/init.d/#{name} start`
		flash[:notice] = out
		redirect_to :action => :services, :vps_id => @vps_id
	end

	def stop_service
		name = params[:ser_name]
		out = `vzctl exec #{@vps_id} /etc/init.d/#{name} stop`
		flash[:notice] = out
		redirect_to :action => :services, :vps_id => @vps_id
	end

	def restart_service
		name = params[:ser_name]
		out = `vzctl exec #{@vps_id} /etc/init.d/#{name} restart`
		flash[:notice] = out
		redirect_to :action => :services, :vps_id => @vps_id
	end

	def services
		output = `vzctl exec #{@vps_id} ls /etc/init.d/`
		@all_services = output.split("\n")
	end	

	def running_processes
 		out=''
 		File.popen("vzctl exec #{@vps_id} ps aux"){|f|f.gets;out=f.read}
 		@procs = out.split("\n")
 	end
	def run_command
	end
	
	def execute_cmd
		@cmd = params[:command][:line]
		@output	= `vzctl exec #{@vps_id} #{@cmd}`
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
		@conf_names = get_conf_files_names
		read_conf
	end
	def change_package
		output = `vzctl set #{@vps_id} --applyconfig #{params[:origin_sample]} --save`
		write_conf(output, 'view_vps')
	end
	def root_pass
	end
	def booting	
	end
	def basic_net
	end
	def adv_net
	end
	def disk_mgt
	end
	def cpu_mgt
	end
	def memory_mgt
	end
	def misc
	end

	def change_name
		new_name = params[:vps][:new_name]
		output = ""
                output += `vzctl set #{@vps_id} --name #{new_name} --save`
                write_conf(output, 'view_vps')
	end
	
	def edit_booting
		output = ""
		output += `vzctl set #{@vps_id} --onboot #{@conf[:booting]} --save`
		write_conf(output, 'view_vps')
	end
	
	def add_ip
		output = ""
		output += `vzctl set #{@vps_id} --ipadd #{@conf[:IP_ADDRESS]} --save`
		write_conf(output, 'basic_net')
	end

	def delete_ip
		ip = params[:ip]
		output = ""
		output += `vzctl set #{@vps_id} --ipdel #{ip} --save`
		write_conf(output, 'basic_net')
	end

	def edit_hostname
		output = ""
		output += `vzctl set #{@vps_id} --hostname #{@conf[:HOSTNAME]} --save`
		write_conf(output, 'basic_net')
	end

	def edit_nameserver
		output = ""
                output += `vzctl set #{@vps_id} --nameserver #{@conf[:NAMESERVER]} --save`
                write_conf(output, 'basic_net')
	end

	def edit_adv_net
		output = ""
		output += `vzctl set #{@vps_id} --numtcpsock #{@conf[:NUMTCPSOCK1]}:#{@conf[:NUMTCPSOCK2]} --save`
		output += `vzctl set #{@vps_id} --tcpsndbuf #{@conf[:TCPSNDBUF1]}:#{@conf[:TCPSNDBUF2]} --save`
		output += `vzctl set #{@vps_id} --othersockbuf #{@conf[:OTHERSOCKBUF1]}:#{@conf[:OTHERSOCKBUF2]} --save`
		output += `vzctl set #{@vps_id} --dgramrcvbuf #{@conf[:DGRAMRCVBUF1]}:#{@conf[:DGRAMRCVBUF2]} --save`
		output += `vzctl set #{@vps_id} --tcprcvbuf #{@conf[:TCPRCVBUF1]}:#{@conf[:TCPRCVBUF2]} --save`
		output += `vzctl set #{@vps_id} --numothersock #{@conf[:NUMOTHERSOCK1]}:#{@conf[:NUMOTHERSOCK2]} --save`
		write_conf(output, 'view_vps')
	end

	def edit_disk_mgt 
		output = ""
		output += `vzctl set #{@vps_id} --diskinodes #{@conf[:DISKINODES1]}:#{@conf[:DISKINODES2]} --save`
		output += `vzctl set #{@vps_id} --diskspace #{@conf[:DISKSPACE1]}:#{@conf[:DISKSPACE2]} --save`
		output += `vzctl set #{@vps_id} --quotatime #{@conf[:QUOTATIME]} --save`
		write_conf(output, 'view_vps')
	end 

	def edit_cpu_mgt 
		output = ""
		output += `vzctl set #{@vps_id} --numproc #{@conf[:NUMPROC1]}:#{@conf[:NUMPROC2]} --save`
		output += `vzctl set #{@vps_id} --cpuunits #{@conf[:CPUUNITS]} --save`
		write_conf(output, 'view_vps' )
	end

	def edit_memory 
		output = ""
		output += `vzctl set #{@vps_id} --kmemsize #{@conf[:KMEMSIZE1]}:#{@conf[:KMEMSIZE2]} --save`
		output += `vzctl set #{@vps_id} --physpages #{@conf[:PHYSPAGES1]}:#{@conf[:PHYSPAGES2]} --save`
		output += `vzctl set #{@vps_id} --dcachesize #{@conf[:DCACHESIZE1]}:#{@conf[:DCACHESIZE2]} --save`
		output += `vzctl set #{@vps_id} --privvmpages #{@conf[:PRIVVMPAGES1]}:#{@conf[:PRIVVMPAGES2]} --save`
		output += `vzctl set #{@vps_id} --lockedpages #{@conf[:LOCKEDPAGES1]}:#{@conf[:LOCKEDPAGES2]} --save`
		output += `vzctl set #{@vps_id} --vmguarpages #{@conf[:VMGUARPAGES1]}:#{@conf[:VMGUARPAGES2]} --save`
		output += `vzctl set #{@vps_id} --oomguarpages #{@conf[:OOMGUARPAGES1]}:#{@conf[:OOMGUARPAGES2]} --save`
		output += `vzctl set #{@vps_id} --shmpages #{@conf[:SHMPAGES1]}:#{@conf[:SHMPAGES2]} --save`
		write_conf(output, 'view_vps')
	end

	def edit_misc
		output = ""
		output += `vzctl set #{@vps_id} --numflock #{@conf[:NUMFLOCK1]}:#{@conf[:NUMFLOCK2]} --save`
		output += `vzctl set #{@vps_id} --numsiginfo #{@conf[:NUMSIGINFO1]}:#{@conf[:NUMSIGINFO2]} --save`
		output += `vzctl set #{@vps_id} --numiptent #{@conf[:NUMIPTENT1]}:#{@conf[:NUMIPTENT2]} --save`
		output += `vzctl set #{@vps_id} --numfile #{@conf[:NUMFILE1]}:#{@conf[:NUMFILE2]} --save`
		output += `vzctl set #{@vps_id} --numpty #{@conf[:NUMPTY1]}:#{@conf[:NUMPTY2]} --save`
		write_conf(output, 'view_vps')
	end

	def monitor_resources
		out = `cat /proc/bc/#{@vps_id}/resources`
		@ubc = out.split("\n")
	end

#Private Methods start here
private
	def distro_name(vps_id)
                first_line = ""
                file = File.open("/vz/private/#{vps_id}/etc/issue")
                file.each_line {|line| first_line = line; break }
                file.close
                x = first_line.split(" ")
                dist_name = x[0]
        end

	def get_conf
		@conf = params[:conf]
	end	
	
	def read_conf
		cnf = Vps.new
                @conf_file = cnf.read_conf_file(@vps_id)
	end
	
	def write_conf(output, to_action)
		flash[:notice] = output
		to_action ||= 'view_vps'
		redirect_to :action => to_action, :vps_id => @vps_id
	end
end
