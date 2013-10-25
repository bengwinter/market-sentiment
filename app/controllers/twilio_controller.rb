class TwilioController < ApplicationController

	def process_sms
	    sender = params[:From].to_s
	    body = params[:Body].to_s
	    
	    client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_TOKEN']
  		client.account.messages.create(
        :from => '+16175443662',
        :to => '+12037709951',
       :body => 'Thank you ' + sender + ' your message was ' + body
      )
      # redirect_to root_url, notice: 'New password successfully delivered to your phone.'
  	end




 end