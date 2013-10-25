class TwilioController < ApplicationController

	def process_sms
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


 end