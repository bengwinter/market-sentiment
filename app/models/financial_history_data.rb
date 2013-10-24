require 'yahoo_finance'

class FinancialHistoryData < ActiveRecord::Base

#nyt methods

	def self.fetch_nyt_news
		date = Date.today.to_s.split(/-/).join
		link_raw = 	"http://api.nytimes.com/svc/search/v2/articlesearch.json?fq=news_desk:(%22Business%22)&begin_date=" + date + "&end_date=" + date + "&api-key=dd560fd468731923ee6fcb7f2213540b:3:6136857"
		link = URI(link_raw)
		json = Net::HTTP.get(link)
		json_crack = JSON.parse(json)
		articles = json_crack["response"]["docs"]
		article_text = []
		articles.each do |article|
			text = article["lead_paragraph"].to_s + " " + article["headline"]["main"].to_s
			article_text << text
		end 
		article_text
	end

	def self.fetch_nyt_sentiment
		sentiment_calculator(fetch_nyt_news)
	end


#financial data methods

	def self.fetch_financial_data(ticker)
		quotes = YahooFinance.quotes([ticker], [:last_trade_price], {raw: false})
		quotes.each do |quote|
			@last_trade_price = quote.last_trade_price.to_f.round(3)
		end
		return @last_trade_price
	end


#seeking alpha methods

	def self.fetch_sa_feed
		link = URI("http://seekingalpha.com/feed.xml")
		xml = Net::HTTP.get(link)
		xml_parse = Crack::XML.parse(xml)
		articles = xml_parse["rss"]["channel"]["item"]
		article_text = []
		articles.each do |article|
			text = article["title"].to_s + " " + article["content"].to_s
			article_text << text
		end 
		return article_text
	end


	def self.scrub_sa_feed
		scrubbed_articles = []
		sa_feed = fetch_sa_feed
		sa_feed.each do |article|
			scrubbed_text = Loofah.fragment(article).scrub!(:whitewash).to_s
			scrubbed_articles << scrubbed_text
		end
		return scrubbed_articles
	end

	def self.fetch_sa_sentiment
		sentiment_calculator(scrub_sa_feed)
	end



#twitter methods

	def self.twitter_fetch_tweets
		client = Twitter::REST::Client.new do |config|
		  config.consumer_key        = ENV['TWITTER_KEY']
		  config.consumer_secret     = ENV['TWITTER_SECRET']
		  config.access_token        = ENV['TWITTER_TOKEN']
		  config.access_token_secret = ENV['TWITTER_TOKEN_SECRET']
		end
		djia_hashtags = '$AXP OR $BA OR $CAT OR $CSCO OR $CVX OR $DD OR $DIS OR $GE OR $GS OR $HD OR $IBM OR $INTC OR $JNJ OR $JPM OR $KO OR $MCD OR $MMM OR $MRK OR $MSFT OR $NKE OR $PFE OR $PG OR $T OR $TRV OR $UNH OR $UTX OR $V OR $VZ OR $WMT OR $XOM'
		tweets_array = []
		tweets = client.search(djia_hashtags, :count => 150, :lang => "en", :result_type => "recent").collect do |tweet|
  			tweets_array << tweet.text.to_s
  		end
  		return tweets_array
	end

	def self.fetch_tweet_sentiment
		sentiment_calculator(twitter_fetch_tweets)
	end


#sentiment calculator

	def self.sentiment_calculator(array)
		Sentimental.load_defaults
		Sentimental.threshold = 0.1
		analyzer = Sentimental.new
		sentiment = []
		array.each do |entry|
			sent_score = analyzer.get_score entry
			sentiment << sent_score
		end
		sentiment_score = (sentiment.inject(0.0) { |sum, element| sum + element } / sentiment.size).round(3)
		return sentiment_score
	end



#update database with sentiment

	def self.update_database
		utc_time = DateTime.now.utc
		time = utc_time.in_time_zone('Eastern Time (US & Canada)')
		nyt_sentiment = fetch_nyt_sentiment.to_f
		self.create(date: time, dia_last: fetch_financial_data('DIA'), spy_last: fetch_financial_data('SPY'), twitter_score: fetch_tweet_sentiment, media_score: nyt_sentiment, investor_score: fetch_sa_sentiment)
	end



#charting methods

	def self.prepare_data_for_chart(data)
		data = FinancialHistoryData.select(data.to_sym).map(&data.to_sym) 
		data_array = []
		data.each do |entry|
			data_array << entry.to_f
		end
		return data_array
	end


	def self.prepare_entry_dates_for_chart
		times_data = FinancialHistoryData.select(:created_at).map(&:created_at) 
		times_array = []
		times_data.each do |entry|
			times_array << entry.strftime("%m-%d-%Y, %I:%M%p")
		end
		return times_array
	end


#sms message methods

	def self.daily_change(open, close)
		(((close - open) / open) * 100).round(2).to_s
	end


	def self.build_message_body
		today = FinancialHistoryData.all.pop(8)
		spy_open = today.first.spy_last.to_f
		dia_open = today.first.dia_last.to_f
		media_open = today.first.media_score.to_f
		twitter_open = today.first.twitter_score.to_f
		investor_open = today.first.investor_score.to_f
		spy_close = today.last.spy_last.to_f
		dia_close = today.last.dia_last.to_f
		media_close = today.last.media_score.to_f
		twitter_close = today.last.twitter_score.to_f
		investor_close = today.last.investor_score.to_f

		spy_change = daily_change(spy_open, spy_close)
		dia_change = daily_change(dia_open, dia_close)
		twitter_change = daily_change(twitter_open, twitter_close)
		investor_change = daily_change(investor_open, investor_close)
		media_change = daily_change(media_open, media_close)

		text_body = 'Sentimyzer daily update: SPY: ' + spy_change + '%, DIA: ' + dia_change + '%, Social: ' + twitter_change + '%, Media: ' + media_change + '%, Investor: ' + investor_change + '%'
		
		return text_body
	end


	def self.send_sms_update
		client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_TOKEN']
  		phone_numbers = User.pluck(:phone_number)
  		phone_numbers.each do |phone_number|
	  		client.account.messages.create(
	        :from => '+16175443662',
	        :to => phone_number,
	       :body => build_message_body
	      )
	  	end
	end

end
