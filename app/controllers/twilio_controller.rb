class TwilioController < ApplicationController

	def verify_number
		sender = params[:From].to_s
		body = params[:Body].to_s.downcase
		@user = User.find_by_phone_number(sender)

		if @user
			if body == 'yes'
				@user.update(verified: true)
				User.send_text('+16175443662', sender, "Thank you! We've verified your number and added you to the Sentimyzer update list")
			else 
				User.send_text('+16175443662', sender, "Whoops. Please respond 'yes' to verify your account. We can't process other responses")
			end
		else
			User.send_text('+16175443662', sender, "Sorry, we don't recognize your number!  Please sign up at http://sentimyzer.com")
		end
	end

	def reset_password
		sender = params[:From].to_s
		body = params[:Body].to_s		
		@user = User.find_by_phone_number(sender)

		if @user
			@user.update(password: body)
			if @user.save!
				User.send_text('+16175443963', sender, "Great! We've saved your new password!")				
			else 
				User.send_text('+16175443963', sender, "We couldn't save your new password.  Please try again.")	
			end
		else 
			User.send_text('+16175443963', sender, "Sorry, we don't recognize your number!  Please sign up at http://sentimyzer.com")	
		end
	end


end