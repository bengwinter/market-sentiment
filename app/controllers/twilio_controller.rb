class TwilioController < ApplicationController

	def verify_number
	    sender = params[:From].to_s
	    body = params[:Body].to_s.downcase
	   	client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_TOKEN']

	   	@user = User.find_by_phone_number(sender)

	   	if @user
		    if body == 'yes'
		    	@user.update(verified: true)
		  		client.account.messages.create(
		        :from => '+16175443662',
		        :to => sender,
		       :body => "Thank you! We've verified your number and added you to the Sentimyzer update list"
		      )
		  	else 
		  		client.account.messages.create(
		        :from => '+16175443662',
		        :to => sender,
		       :body => "Whoops. Please respond 'yes' to verify your account. We can't process other responses"
		      )
		  	end
		else
		 	client.account.messages.create(
		        :from => '+16175443662',
		        :to => sender,
		       :body => "Sorry, we don't recognize your number!  Please sign up at http://sentimyzer.com"
		      )
		 end
  	end

  def reset_password
	sender = params[:From].to_s
    body = params[:Body].to_s
   	client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_TOKEN']
   	
   	@user = User.find_by_phone_number(sender)

   	if @user
	    @user.update(password: body)
	    	if @user.save!
		  		client.account.messages.create(
		        :from => '+16175443963',
		        :to => sender,
		       :body => "Great! We've saved your new password!"
		      )
		  	else 
		  		client.account.messages.create(
		        :from => '+16175443963',
		        :to => sender,
		       :body => "We couldn't save your new password.  Please try again."
		      )
		  	end
  	else 
  		client.account.messages.create(
        :from => '+16175443963',
        :to => sender,
       :body => "Sorry, we don't recognize your number!  Please sign up at http://sentimyzer.com"
      )
  	end
  end


 end