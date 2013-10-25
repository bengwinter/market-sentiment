require 'bcrypt'

class User < ActiveRecord::Base
	before_save :encrypt_password
	before_create { generate_token(:auth_token) }

	include BCrypt
	attr_accessor :password

	  validates_confirmation_of :password
	  validates_presence_of :password, :on => :create
	  validates_presence_of :phone_number
	  validates_uniqueness_of :phone_number
	  # validates_format_of :phone_number, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create

	def generate_token(column)
		begin 
			self[column] = SecureRandom.urlsafe_base64
		end while User.exists?(column => self[column])
	end


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
