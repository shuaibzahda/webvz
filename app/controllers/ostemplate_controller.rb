class OstemplateController < ApplicationController
	before_filter :authorize
	 before_filter :authorize_admin
	before_filter :get_template_name
	before_filter :get_vps_id, :only => [:recreate_template, :make_new_template]
	def list_templates
		list = `ls /vz/template/cache/*.tar.gz`
		all = list.split("\n")
		@templates = []
		for t in all 
			n = t.split("/vz/template/cache/")
			@templates << n[1]
		end
		@templates
	end
	
	def recreate
		i = `vzlist -aH`
		k = `vzlist -aHn`
		@rows = extract_vps_values(i, k)
	end

	def recreate_template
	end

	def make_new_template
		name = params[:temp][:name]
		new_name = name + ".tar.gz"
		templates = list_templates	
		if templates.include?(new_name)
			flash[:notice] = "<b> #{name} </b> is used, choose different name."
			redirect_to :action => :recreate_template, :vps_id => @vps_id
		else
			#this is to stop the container and delete the IP addresses
			`vzctl stop #{@vps_id}`	
			`vzctl set  #{@vps_id} --ipdel all --save`
			#this accesses the private directory of the container and make a tar file in the cache directory
			`cd /vz/private/#{@vps_id}; tar czf /vz/template/cache/#{new_name} .`	
			flash[:notice] = "<b> #{name} </b> template has been created successfully."
			redirect_to :action => :list_templates
		end	
	end

	def delete_template
		if system("rm -rf /vz/template/cache/#{@name}")
			flash[:notice] = "#{@name} template was deleted successfully."
			redirect_to :action => :list_templates
		else
			flash[:notice] = "Failed to delete #{@name} template."
			redirect_to :action => :list_templates
		end
	end

	def copy_template
	end
	
	def transfer_file
		username = params[:dest][:username]
		address = params[:dest][:add]
		#check for the existence of the IP address in the known_hosts files first	
		if system("scp /vz/template/cache/#{@name} #{username}@#{address}:/vz/template/cache/")
			flash[:notice] = "#{@name} template was copied successfully to #{username}@#{address}."
			redirect_to :action => :list_templates
		else
			flash[:notice] = "Failed to copy #{@name} template to <b> #{username}@#{address} </b>. <br> Make sure that you have keyed in the right  username and IP address of the destination. <br> Or Read the note in the page below."
                        redirect_to :action => :copy_template, :name => @name
		end
	end
#private methods
	private
	
	def get_template_name
		@name = params[:name]
	end
end
