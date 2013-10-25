class UsersController < ApplicationController

	def new
		@user = User.new
	end

  # process the signup form
	def create
	  	@user = User.new(user_params)
	  	client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_TOKEN']
	  	if @user.save
	  		client.account.messages.create(
		        :from => '+16175443662',
		        :to => @user.phone_number.to_s,
		       :body => "Welcome to Sentimyzer! Please respond 'yes' to verify your phone number!"
		      )
	  		flash[:notice] = "Thanks for signing up. Please respond to our text message to verify your phone number." 
			cookies.permanent[:auth_token] = @user.auth_token
	  		redirect_to root_url
	  	else
	  		redirect_to root_url, :notice => "Registration failed. Please try again."
	  	end
	end


	def update
	  	user_id = current_user.id
	  	@user = User.find(user_id)

	    respond_to do |format|
	      if @user.update(user_params)
	        format.html { render action: 'show' , notice: 'Your profile was successfully updated.' }
	      else
	        format.html { render action: 'edit' }
	      end
	    end
	end

	 
	def destroy
		user_id = current_user.id
    	user = User.find(user_id)
    	session[:user_id] = nil
    	user.destroy

    	redirect_to root_url, notice: 'You were successfully unsubscribed from our alert list'
  	end


  	def forgot_password
  	end


  	def send_password
  		client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_TOKEN']
  		user = User.find_by_phone_number(params[:phone_number])
  		random_password = SecureRandom.hex(3)
  		user.password = random_password
  		user.save!
  		client.account.messages.create(
        :from => '+16175443662',
        :to => user.phone_number,
       :body => 'Your new Sentimyzer password is' + ' ' + random_password
      )
      redirect_to root_url, notice: 'New password successfully delivered to your phone.'
  	end
  


  private

  def user_params
  	params.require(:user).permit(:email, :phone_number, :password, :password_confirmation)
  end


end