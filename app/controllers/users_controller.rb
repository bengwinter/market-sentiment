class UsersController < ApplicationController

	def new
		@user = User.new
	end

  # process the signup form
	def create
	  	@user = User.new(user_params)
	  	if @user.save
		  	User.send_text('+16175443662', @user.phone_number.to_s, "Welcome to Sentimyzer! Please respond 'yes' to verify your phone number!")
	  		flash[:notice] = "Thanks for signing up. Please respond to our text message to verify your phone number." 
				cookies.permanent[:auth_token] = @user.auth_token
	  		redirect_to root_url
	  	else
	  		redirect_to root_url, :notice => "Registration failed. Please try again."
	  	end
	end

	# verify user phone number
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

	# update a user profile 
	# code may be unused --- check this. 
	# def update
	#   	user_id = current_user.id
	#   	@user = User.find(user_id)

	#     respond_to do |format|
	#       if @user.update(user_params)
	#         format.html { render action: 'show' , notice: 'Your profile was successfully updated.' }
	#       else
	#         format.html { render action: 'edit' }
	#       end
	#     end
	# end

	 
	def destroy
		user_id = current_user.id
    	user = User.find(user_id)
    	session[:user_id] = nil
    	user.destroy

    	redirect_to root_url, notice: 'You were successfully unsubscribed from our alert list'
  end

				User.send_text('+16175443662', sender, "Thank you! We've verified your number and added you to the Sentimyzer update list")

	# send password to user who forgets or wants to reset password
	def send_password
		if current_user
			# for signed in users who request to change password
			User.send_text('+16175443963', current_user.phone_number, "You requested to reset your password on Sentimyzer.com. Respond to this text with your desired new password.")
    	redirect_to root_url, notice: 'Respond to our text message with your desired new password.'
		elsif params[:phone_number]
			# for users who forget their password and use the forget password form
			User.send_text('+16175443963', params[:phone_number], "You requested to reset your password on Sentimyzer.com. Respond to this text with your desired new password.")
    	redirect_to root_url, notice: 'Respond to our text message with your desired new password.'
		else
			redirect_to root_url, notice: 'We did not recognize that phone number.  Please try again or create a new account.'
		end
	end

	# reset user password upon response
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
  

  private

  def user_params
  	params.require(:user).permit(:email, :phone_number, :password, :password_confirmation)
  end


end