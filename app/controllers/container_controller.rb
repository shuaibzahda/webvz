class ContainerController < ApplicationController

	before_filter :authorize
	before_filter :authorize_admin, :only => [:vzmigrate, :migrate_vps, :new_vps, :create_vps, :destroy_vps]
	before_filter :get_vps_id, :only => [:start_vps, :destroy_vps, :stop_vps, :restart_vps, :migrate_vps, :vzmigrate, :assign_to_owner, :create_backup]
	before_filter :is_vz_running, :except => [:index, :vz_status, :start_vz, :about]	

	def vzmigrate
	#  --ssh=options   look how to do it
		@rec = params[:vps]
		@cmd = "vzmigrate "
		@cmd += " -r yes " if @rec[:r].include?("yes")
		@cmd += " -v " if @rec[:v].include?("yes")
		@cmd += " --online " if @rec[:online].include?("yes")
		@cmd += " --keep-dst " if @rec[:keepdst].include?("yes")
		if not @rec[:ip].blank? && @vps_id
			@cmd += " #{@rec[:ip]} #{@vps_id} "
			output = `#{@cmd}`
			flash[:notice] = output
			redirect_to :action => :list_vps	
		else
			flash[:notice] = "IP Address incorrect"
			redirect_to :action => :migrate_vps, :vps_id => @vps_id
		end
	end	

	def migrate_vps
	end	
	
	def list_vps
		@status = params[:status]
		@status ||= "all"
		if @status.include?("running")
			i = `vzlist -H`
			k = `vzlist -Hn`
	        elsif @status.include?("stopped")
			i = `vzlist -SH`
			k = `vzlist -SHn`
	        else
			i = `vzlist -aH`
			k = `vzlist -aHn`
			@status = ""
		end
		@rows = extract_vps_values(i, k)
	end
	
	def new_vps
		get_users
		#this is to get the template names
		tmpl = `ls /vz/template/cache/`
        	names = tmpl.split("\n")	
		@new_names = []
        	for name in names
                	n = name.split(".tar")
                	@new_names << [n[0]]
        	end
		@conf_names = get_conf_files_names
	end
	
	def create_vps
		#This will create new vps based on the values provided by the user
		temp_name = params[:vps][:os_name]
		conf_file = params[:vps][:conf_file]
		vps_id = params[:vps][:vps_id]
		vps_name = params[:vps][:vps_name]
		ip_address = params[:vps][:ipadd]
		hostname = params[:vps][:hostname]	
		nameserver = params[:vps][:nameserver]
		booting = params[:vps][:booting]
		root_pass = params[:vps][:root_pass]
		starting = params[:vps][:starting]
		output = ""
		user_id = params[:vps][:user_id]
	
		@the_vps = Vps.new
		@the_vps.cnt_id = vps_id.to_i
		@the_vps.user_id = user_id

		#here we start the checking of id, ip, hostname
		i = `vzlist -aH`
		k = `vzlist -aHn`
		rows = extract_vps_values(i, k)	
		
		# index 0, 3, 4		
		ips = []
		ids = []
		hostnames = []	
		
		for row in rows
			ids << row[0]
			ips << row[3]
			hostnames << row[4]
		end
		err = ""

		if vps_id.blank? or ids.include?(vps_id)  
			err = "<b>#{vps_id}</b> VPS ID is used by another VPS, please choose another one.<br>" 
			err = "Error: Blank or Invalid VPS ID.<br>"  if vps_id.blank?
		end

		if temp_name.blank?
			err += "Choose OS template from the list"
		end

		if ips.include?(ip_address)  
			err += "<b>#{ip_address}</b> IP Address is used by another VPS, please choose another one.<br>" 
		end

		if hostnames.include?(hostname)
                        err += "<b>#{hostname}</b> Hostname is used by another VPS, please choose another one.<br>"       
                end

		unless err.size.zero?
			flash[:notice] = err
			new_vps
			render :action => :new_vps
		else
		#the creation process starts here
			if conf_file.blank?
				output = `vzctl create #{vps_id} --ostemplate #{temp_name}`
			else
				output += `vzctl create #{vps_id} --ostemplate #{temp_name} --config #{conf_file}`
			end

			output += `vzctl set #{vps_id} --name #{vps_name} --save` unless vps_name.blank?
			output += `vzctl set #{vps_id} --ipadd #{ip_address} --save` unless ip_address.blank?
			output += `vzctl set #{vps_id} --hostname #{hostname} --save` unless hostname.blank?
			output += `vzctl set #{vps_id} --nameserver #{nameserver} --save` unless nameserver.blank?
			output += `vzctl set #{vps_id} --onboot #{booting} --save` unless booting.blank?
			output += `vzctl set #{vps_id} --userpasswd root:#{root_pass}` unless root_pass.blank?
			output += `vzctl start #{vps_id}` if starting == "yes" 
			if @the_vps.save
				flash[:notice] = output
			else
				flash[:notice] = "Failed to assign the VPS to a user, however it was created successfully. <br> #{output}"
			end
				redirect_to :action => :list_vps
		end			
	end

	def assign_to_owner
		get_users	
		@owner = Vps.find_by_cnt_id(params[:vps_id])
	end

	def change_owner
		vps = Vps.find_by_cnt_id(params[:vps_id])
		#if the container was not in the database
		if vps
			vps.user_id = params[:vps][:user_id]
		else
			vps = Vps.new
			vps.cnt_id = params[:vps_id].to_i
                	vps.user_id = params[:vps][:user_id]
		end
		
		#save the owner
		if vps.save
			flash[:notice] = "Owner of container #{vps.cnt_id} is #{vps.user.name}"	
			redirect_to :action => :list_vps
		else
			render :action => :assign_to_owner_
		end
	end

	def vpses_of_user
		@user = User.find_by_id(params[:user_id])
		ids = @user.vpss.map {|vps| [vps.cnt_id]}	
		i = `vzlist -aH #{ids.join(" ")}`
		k = `vzlist -aHn #{ids.join(" ")}`
		@rows = extract_vps_values(i, k)
		@status = ""
		render :action => :list_vps	
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
	
	def destroy_vps
		msg = `vzctl destroy #{@vps_id}`
		#delete entry from database
		Vps.find_by_cnt_id(@vps_id).destroy
		redirect_msg(@vps_id, "desroyed\n"+ msg)
	end

	def backups
		files = `ls /vz/dump/*.tar`
		@dumps = []
		for file in files
			@dumps << file.split("/vz/dump/")
		end
	end

	def create_backup
		msg = `vzdump --suspend #{@vps_id}`
		redirect_msg(@vps_id, "has been backed up\n"+ msg)
	end
		
	def restore
		get_users
		@dump_id = params[:dump_id]
	end

	def restore_dump
		get_users
		if params[:dump][:id].blank? || params[:dump][:id] == params[:dump_id] 
			flash[:notice] = "The Container ID must be unique"
			@dump_id = params[:dump_id]
			render :action => :restore, :dump_id =>  params[:dump_id]
		elsif params[:dump][:user_id].blank?
			flash[:notice] = "Please assign the container into an owner."
                        @dump_id = params[:dump_id]
                        render :action => :restore, :dump_id =>  params[:dump_id] 
		else
			msg = `vzdump --restore /vz/dump/vzdump-#{params[:dump_id]}.tar #{params[:dump][:id]}`
			vps = Vps.new
			vps.user_id = params[:dump][:user_id]
			vps.cnt_id = params[:dump][:id]
			if vps.save
				flash[:notice] = "Container #{params[:dump_id]} has been restored into #{params[:dump][:id]}"
				redirect_to :action => :list_vps
			else
				flash[:notice] = "Failed to save the owner of the container into database"
				redirect_to :action => :list_vps
			end
		end
	end
	
	def delete_dump
		`rm -rf /vz/dump/vzdump-#{params[:dump_id]}.tar`	
		flash[:notice] = "vzdump-#{params[:dump_id]}.tar has been deleted successfuly."
		redirect_to :action => :backups
	end
	
	def backup_all_containers
		msg = `vzdump --suspend --all --mailto root`
		flash[:notice] = "All the containers have been backed up. <br> #{msg}." 		
		redirect_to :action => :backups
	end

	def backup_user_containers
		get_users		
	end

	def create_user_backup
		vpses = Vps.find(:all, :conditions => "user_id = '#{params[:dump][:user_id]}'")
		user = User.find(params[:dump][:user_id])	
		unless vpses.size.zero?
			msg = ""
			ids = []
			for vps in vpses
				msg += `vzdump --suspend #{vps.cnt_id}`
				ids << vps.cnt_id
			end
			flash[:notice] = "#{ids.join(", ")} have been backed up for #{user.name}."
			redirect_to :action => :backups
		else
			flash[:notice] = "#{user.name} has no containers on this server. Nothing was backed up."
			redirect_to :action => :backup_user_containers	
		end
	end

#Private methods
private 

	def redirect_msg (vps_id, msg)
		flash[:notice] = "Container #{vps_id} #{msg}"
		redirect_to :action => :list_vps
	end

	def get_users
		@users = User.find(:all).map {|user| [user.name, user.id]}
	end
end
