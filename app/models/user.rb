class User < ActiveRecord::Base
   require "digest/sha1"
   has_many :vpss 
   validates_uniqueness_of :username
   validates_presence_of :username, :password, :activated, :country, :email, :name, :authority
   
   def self.encrypt_password(password)
     return Digest::SHA1.hexdigest(password)
   end
   
   def self.authunticate(username, password)
    passwd = encrypt_password(password)
    user = self.find_by_username(username)
    if user
      if user.password != passwd 
          user = nil
      end
    end
    user  
  end
  
end
