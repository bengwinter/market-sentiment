require 'yahoo_finance'

class FinancialHistoryData < ActiveRecord::Base

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
		return article_text
	end


	def self.nyt_sentiment_calc
		Sentimental.load_defaults
		Sentimental.threshold = 0.1
		analyzer = Sentimental.new
		nyt_text = fetch_nyt_news
		sentiment = []
		nyt_text.each do |article|
			sent_score = analyzer.get_score article
			sentiment << sent_score
		end
		sentiment
	end


	def self.fetch_nyt_sentiment
		sentiment = nyt_sentiment_calc
		sent_round = (sentiment.inject(0.0) { |sum, element| sum + element } / sentiment.size).round(3)
		return sent_round
	end


	def self.fetch_financial_data(ticker)
		quotes = YahooFinance.quotes([ticker], [:last_trade_price], {raw: false})
		quotes.each do |quote|
			@last_trade_price = quote.last_trade_price.to_f.round(3)
		end
		return @last_trade_price
	end


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


	def self.sa_sent_calc
		Sentimental.load_defaults
		Sentimental.threshold = 0.1
		analyzer = Sentimental.new
		sentiment = []
		scrubbed_feed = scrub_sa_feed
		scrubbed_feed.each do |article|
			sent_score = analyzer.get_score article
			sentiment << sent_score
		end
		return sentiment
	end


	def self.fetch_sa_sentiment
		sentiment = sa_sent_calc
		sent_round = (sentiment.inject(0.0) { |sum, element| sum + element } / sentiment.size).round(3)
		return sent_round
	end


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


	def self.tweets_sent_calc
		tweets = twitter_fetch_tweets
		Sentimental.load_defaults
		Sentimental.threshold = 0.1
		analyzer = Sentimental.new
		sentiment = []
		tweets.each do |tweet|
			sent_score = analyzer.get_score tweet
			sentiment << sent_score
		end
		sentiment
	end


	def self.fetch_tweet_sentiment
		sentiment = tweets_sent_calc
		sent_round = (sentiment.inject(0.0) { |sum, element| sum + element } / sentiment.size).round(3)
		return sent_round
	end


	def self.update_database
		utc_time = DateTime.now.utc
		time = utc_time.in_time_zone('Eastern Time (US & Canada)')
		nyt_sentiment = fetch_nyt_sentiment.to_f
		self.create(date: time, dia_last: fetch_financial_data('DIA'), spy_last: fetch_financial_data('SPY'), twitter_score: fetch_tweet_sentiment, media_score: nyt_sentiment, investor_score: fetch_sa_sentiment)
	end


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

		spy_change = (((spy_close - spy_open) / spy_open) * 100).round(2)
		dia_change = (((dia_close - dia_open) / dia_open) * 100).round(2)
		twitter_change = (((twitter_close - twitter_open) / twitter_open) * 100).round(2)
		investor_change = (((investor_close - investor_open) / investor_open) * 100).round(2)
		media_change = (((media_close - media_open) / media_open) * 100).round(2)

		text_body = 'Sentimyzer daily update: SPY: ' + spy_change.to_s + '%, DIA: ' + dia_change.to_s + '%, Social: ' + twitter_change.to_s + '%, Media: ' + media_change.to_s + '%, Investor: ' + investor_change.to_s + '%'
		
		return text_body
	end


	def self.send_sms_update
		client = Twilio::REST::Client.new ENV['TWILIO_ID'], ENV['TWILIO_TOKEN']
  		phone_numbers = User.pluck(:phone_number)
  		body = self
  		phone_numbers.each do |phone_number|
	  		client.account.messages.create(
	        :from => '+16175443662',
	        :to => phone_number,
	       :body => build_message_body
	      )
	  	end
	end

end
