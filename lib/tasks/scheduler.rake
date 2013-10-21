desc "Cron job configuration for Heroku scheduler. Fetches daily update from data sources"
task :update_feed => :environment do
  puts "Updating database with today's sentiment and performance data..."
	FinancialHistoryData.update_database
  puts "finished daily update."
end
