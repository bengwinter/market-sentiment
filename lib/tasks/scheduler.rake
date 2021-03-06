desc "Cron job configuration for Heroku scheduler. Fetches daily update from data sources"
task :update_feed => :environment do
  puts "Updating database with most recent sentiment and performance data..."
        FinancialHistoryData.update_database
  puts "finished data fetch and database update."
end

desc "Daily text message to verified users"
task :daily_message => :environment do
  puts "Sending daily user SMS messages..."
        FinancialHistoryData.send_sms_update
  puts "finished sending SMS messages."
end

desc "Ping URL every 15 minutes to keep heroku server awake"
task :url_ping do
	puts "Pinging http://www.sentimyzer.com..."
    uri = URI('http://www.sentimyzer.com')
    Net::HTTP.get_response(uri)
  puts "Finished pinging url"
end