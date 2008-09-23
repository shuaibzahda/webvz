class ConfigfileController < ApplicationController
	before_filter :authorize
	before_filter :authorize_admin

	def split_resources
	end	

	def generate_conf
		@info = params[:split]
		#vzsplit [-f config_name] | [-n numves] | [-s swap_size]
		cmd = "vzsplit "
		if @info[:name].blank? || @info[:ve].blank? 
			flash[:notice] = "Incorrect or blank configuration file name and/or number of VEs."
			redirect_to :action => :split_resources
		elsif @info[:name].include?(" ") || @info[:name].include?("*")
			flash[:notice] = "Wrong file name: space is not allowed."
                        redirect_to :action => :split_resources
		else
			cmd += " -f #{@info[:name]} "
			cmd += " -n #{@info[:ve]} "
			cmd += " -s #{@info[:swap]} " unless @info[:swap].blank? 
			@output = `#{cmd}`
			flash[:notice] = " #{@info[:name]} configuration file was created successfully. You can use it now."
			redirect_to :action => :list_conf_file
		end
	end	

	def edit_conf_file
		@file_name = params[:conf_name]
		path = "/etc/vz/conf/ve-#{@file_name}.conf-sample"
                cnf = Vps.new
                @conf_file = cnf.read_sample_conf_file(path)
	end

	def delete_conf_file
		@file_name = params[:conf_name]
                `rm -rf /etc/vz/conf/ve-#{@file_name}.conf-sample`
		flash[:notice] = "#{@file_name} configuration file was deleted." 
                redirect_to :action => :list_conf_file
	end
=begin
	def validate_conf_file
		@file_name = params[:conf_name]
		output = `vzcfgvalidate /etc/vz/conf/ve-#{@file_name}.conf-sample`
		flash[:notice] = output 
		redirect_to :action => :list_conf_file
	end
=end
	def list_conf_file
		@conf_names = get_conf_files_names	
	end
	def new_conf_file
		@conf_file = {}
		@conf_file["NUMTCPSOCK"]="360:360"
		@conf_file["KMEMSIZE"]="11055923:11377049"
		@conf_file["LOCKEDPAGES"]="256:256"
		@conf_file["PRIVVMPAGES"]="65536:69632"
		@conf_file["SHMPAGES"]="21504:21504"
		@conf_file["NUMPROC"]="240:240"
		@conf_file["PHYSPAGES"]="0:2147483647"
		@conf_file["VMGUARPAGES"]="33792:2147483647"
		@conf_file["OOMGUARPAGES"]="26112:2147483647"
		@conf_file["NUMFLOCK"]="188:206"
		@conf_file["NUMPTY"]="16:16"
		@conf_file["NUMSIGINFO"]="256:256"
		@conf_file["TCPSNDBUF"]="1720320:2703360"
		@conf_file["TCPRCVBUF"]="1720320:2703360"
		@conf_file["OTHERSOCKBUF"]="1126080:2097152"
		@conf_file["DGRAMRCVBUF"]="262144:262144"
		@conf_file["NUMOTHERSOCK"]="360:360"
		@conf_file["DCACHESIZE"]="3409920:3624960"
		@conf_file["NUMFILE"]="9312:9312"
		@conf_file["AVNUMPROC"]="180:180"
		@conf_file["NUMIPTENT"]="128:128"
		@conf_file["DISKSPACE"]="1048576:1153024"
		@conf_file["DISKINODES"]="200000:220000"
		@conf_file["QUOTATIME"]="0"
		@conf_file["CPUUNITS"]="1000"
	end

	def create_new_conf_file
		@conf = params[:conf]
		@conf_file = {}
		name = params[:file][:name] 
		
		if name.blank?
			flash[:notice] = "Configuration file name cannot be blank."
			redirect_to :action => :new_conf_file
		elsif name.include?(" ")
			flash[:notice] = "Wrong file name: space is not allowed."
                        redirect_to :action => :new_conf_file
		else
		@conf_file["ONBOOT"] = "\"" + "yes" +  "\"\n"
		@conf_file["AVNUMPROC"]= "\"" + "180:180"  +  "\"\n"
		@conf_file["NUMTCPSOCK"] = "\"" + @conf["NUMTCPSOCK1"] + ":" + @conf["NUMTCPSOCK2"] +  "\"\n"	
		@conf_file["TCPSNDBUF"] = "\"" + @conf["TCPSNDBUF1"] + ":" + @conf["TCPSNDBUF2"] +  "\"\n"	
		@conf_file["OTHERSOCKBUF"] = "\"" + @conf["OTHERSOCKBUF1"] + ":" + @conf["OTHERSOCKBUF2"] +  "\"\n"	
		@conf_file["DGRAMRCVBUF"] = "\"" + @conf["DGRAMRCVBUF1"] + ":" + @conf["DGRAMRCVBUF2"] +  "\"\n"	
		@conf_file["TCPRCVBUF"] = "\"" + @conf["TCPRCVBUF1"] + ":" + @conf["TCPRCVBUF1"] +  "\"\n"		
		@conf_file["NUMOTHERSOCK"] = "\"" + @conf["NUMOTHERSOCK1"] + ":" + @conf["NUMOTHERSOCK2"] +  "\"\n"
		@conf_file["DISKINODES"] = "\"" + @conf["DISKINODES1"] + ":" + @conf["DISKINODES2"] +  "\"\n"	
		@conf_file["DISKSPACE"] = "\"" + @conf["DISKSPACE1"] + ":" + @conf["DISKSPACE2"] +  "\"\n"	
		@conf_file["QUOTATIME"] =  "\"" + @conf["QUOTATIME"]  +  "\"\n" unless  @conf_file["QUOTATIME"].blank?
		@conf_file["NUMPROC"] = "\"" + @conf["NUMPROC1"] + ":" + @conf["NUMPROC2"] +  "\"\n"	
		@conf_file["CPUUNITS"] =  "\"" + @conf["CPUUNITS"]  +  "\"\n"
		@conf_file["KMEMSIZE"] = "\"" + @conf["KMEMSIZE1"] + ":" + @conf["KMEMSIZE2"] +  "\"\n"	
		@conf_file["PHYSPAGES"] = "\"" + @conf["PHYSPAGES1"] + ":" + @conf["PHYSPAGES2"] +  "\"\n"	
		@conf_file["DCACHESIZE"] = "\"" + @conf["DCACHESIZE1"] + ":" + @conf["DCACHESIZE2"] +  "\"\n"	
		@conf_file["PRIVVMPAGES"] = "\"" + @conf["PRIVVMPAGES1"] + ":" + @conf["PRIVVMPAGES2"] +  "\"\n"	
		@conf_file["LOCKEDPAGES"] = "\"" + @conf["LOCKEDPAGES1"] + ":" + @conf["LOCKEDPAGES2"] +  "\"\n"	
		@conf_file["VMGUARPAGES"] = "\"" + @conf["VMGUARPAGES1"] + ":" + @conf["VMGUARPAGES2"] +  "\"\n"	
		@conf_file["OOMGUARPAGES"] = "\"" + @conf["OOMGUARPAGES1"] + ":" + @conf["OOMGUARPAGES2"] +  "\"\n"	
		@conf_file["SHMPAGES"] = "\"" + @conf["SHMPAGES1"] + ":" + @conf["SHMPAGES2"] +  "\"\n"
		@conf_file["NUMFLOCK"] = "\"" + @conf["NUMFLOCK1"] + ":" + @conf["NUMFLOCK2"] +  "\"\n" 
                @conf_file["NUMSIGINFO"] = "\"" + @conf["NUMSIGINFO1"] + ":" + @conf["NUMSIGINFO2"] +  "\"\n"
                @conf_file["NUMIPTENT"] = "\"" + @conf["NUMIPTENT1"] + ":" + @conf["NUMIPTENT2"] +  "\"\n" 
                @conf_file["NUMFILE"] = "\"" + @conf["NUMFILE1"] + ":" + @conf["NUMFILE2"] +  "\"\n"
                @conf_file["NUMPTY"] = "\"" + @conf["NUMPTY1"] + ":" + @conf["NUMPTY2"] +  "\"\n"
		write_conf(name, @conf_file)
		end
	end
end
