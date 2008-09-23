class Vps < ActiveRecord::Base 
	attr_accessor :vps_id, :name
	validates_presence_of :cnt_id, :user_id
	belongs_to :user

	def extract_values(file)
		all_lines = file.readlines
                conf_det = {}
                for line in all_lines
                        unless line.include?("#")
                                val = line.split("=")
                                conf_det[val[0]] = val[1]
                        end

                end
                return conf_det
	end

	def read_conf_file(vps_id)
		file = File.open("/etc/vz/conf/#{vps_id}.conf", "r")	
		extract_values(file)		
	end
	
	def read_sample_conf_file(name)
		file = File.open("#{name}", "r")	
		extract_values(file)
	end

	def write_to_conf_file(name, conf_file)
		new_file = File.open("/etc/vz/conf/ve-#{name}.conf-sample", "w")
                for k, v in conf_file
                        unless k["\n"]
                                @text = k.to_s+"="+v.to_s
                                new_file.write(@text)
                        end
                end
                new_file.close	
	end
end
