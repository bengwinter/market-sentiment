require 'bcrypt'

class User < ActiveRecord::Base
	before_save :encrypt_password

	include BCrypt
	attr_accessor :password

	  validates_confirmation_of :password
	  validates_presence_of :password, :on => :create
	  validates_presence_of :phone_number
	  validates_uniqueness_of :phone_number

	def encrypt_password
		if password.present?
			self.password_salt = BCrypt::Engine.generate_salt
			self.password_digest = BCrypt::Engine.hash_secret(password, self.password_salt)
		else
			nil
		end
	end	


	def self.authenticate(phone_number, password)
		user = self.find_by_phone_number(phone_number)
		if user && user.password_digest == ::BCrypt::Engine.hash_secret(password, user.password_salt)
			user
		else
			nil
		end
	end

end
