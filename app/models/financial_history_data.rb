require 'yahoo_finance'

class FinancialHistoryData < ActiveRecord::Base

# main sentiment calculation method
	def self.sentiment_calculator(array)
		Sentimental.load_defaults
		Sentimental.threshold = 0.25
		analyzer = Sentimental.new
		sentiment_raw = []
		sentiment_keys = []
		array.each do |entry|
			raw = analyzer.get_score entry
			sent = analyzer.get_sentiment entry
			sentiment_raw << raw
			sentiment_keys << sent
		end
		sentiment_score = (sentiment_raw.inject(0.0) { |sum, element| sum + element } / sentiment_raw.size).round(3)
		sentiment_count = sentiment_keys.dup_hash
		return {:score => sentiment_score, :count => sentiment_count}
	end

# fetch and format standard xml feeds

	def self.fetch_standard_xml(link)
		link = URI(link.to_s)
		xml = Crack::XML.parse(Net::HTTP.get(link))
		articles = xml["rss"]["channel"]["item"]
		return articles	
	end

	def self.organize_standard_xml(entries)
		entry_text = []
		entries.each do |entry|
			entry_text << entry["title"].to_s + ". " + entry["description"].to_s
		end
		return entry_text
	end

	def self.scrub_entries(array)
		scrubbed_content = []
		array.each do |x|
			scrubbed_content << Loofah.fragment(x).scrub!(:whitewash).to_s
		end
		return scrubbed_content
	end

	def self.fetch_sentiment_standard_xml(link)
		sentiment_calculator(scrub_entries(organize_standard_xml(fetch_standard_xml(link.to_s))))
	end

# forbes real time news feed
	def self.fetch_forbes_sentiment
		fetch_sentiment_standard_xml('http://www.forbes.com/real-time/feed2/')
	end

# cnbc top news feed
	def self.fetch_cnbc_sentiment
		fetch_sentiment_standard_xml('http://www.cnbc.com/id/100003114/device/rss/rss.html')
	end

# ychart news feed
	def self.fetch_ycharts_sentiment
		fetch_sentiment_standard_xml('http://finance.yahoo.com/news/provider-ycharts/rss')
	end

# financial data methods
	def self.fetch_financial_data(ticker)
		quotes = YahooFinance.quotes([ticker], [:last_trade_price], {raw: false})
		quotes.each do |quote|
			@last_trade_price = quote.last_trade_price.to_f.round(3)
		end
		return @last_trade_price
	end

# nyt methods
	def self.fetch_nyt_news
		date = Date.today.to_s.split(/-/).join
		link_raw = 	"http://api.nytimes.com/svc/search/v2/articlesearch.json?fq=news_desk:(%22Business%22)&begin_date=" + date + "&end_date=" + date + "&api-key=dd560fd468731923ee6fcb7f2213540b:3:6136857"
		link = URI(link_raw)
		json_parse = JSON.parse(Net::HTTP.get(link))
		articles = json_parse["response"]["docs"]
		article_text = []
		articles.each do |article|
			text = article["lead_paragraph"].to_s + " " + article["headline"]["main"].to_s
			article_text << text
		end 
		article_text
	end

	def self.fetch_nyt_sentiment
		sentiment_calculator(scrub_entries(fetch_nyt_news))
	end

#seeking alpha methods
	def self.fetch_scrubbed_sa_feed
		entry_text = []
		entries = fetch_standard_xml("http://seekingalpha.com/feed.xml")
		entries.each do |entry|
			entry_text << entry["title"].to_s + ". " + entry["content"].to_s
		end
		return scrub_entries(entry_text)
	end

	def self.fetch_sa_sentiment
		sentiment_calculator(fetch_scrubbed_sa_feed)
	end

#twitter fetch, scrub, and analysis
	def self.fetch_tweets
		djia_hashtags = '$AXP OR $BA OR $CAT OR $CSCO OR $CVX OR $DD OR $DIS OR $GE OR $GS OR $HD OR $IBM OR $INTC OR $JNJ OR $JPM OR $KO OR $MCD OR $MMM OR $MRK OR $MSFT OR $NKE OR $PFE OR $PG OR $T OR $TRV OR $UNH OR $UTX OR $V OR $VZ OR $WMT OR $XOM'
		tweets_array = []
		tweets = $twitter_client.search(djia_hashtags, :count => 100, :lang => "en", :result_type => "recent").collect do |tweet|
  			tweets_array << tweet.text.to_s
  	end
  	return tweets_array
	end

	def self.fetch_tweet_sentiment
		sentiment_calculator(scrub_entries(fetch_tweets))
	end

# collect data and update database with sentiment
# still needs drying up ----------------------------------------
	def self.fetch_media_sentiment
		ycharts = fetch_ycharts_sentiment[:score].to_f
		cnbc = fetch_cnbc_sentiment[:score].to_f
		forbes = fetch_forbes_sentiment[:score].to_f
		nyt = fetch_nyt_sentiment[:score].to_f
		return ((ycharts + cnbc + forbes + nyt) / 4).round(3)
	end

	def self.update_database
		#fetch seeking alpha data
		sa_sent = fetch_sa_sentiment
		sa_sent_score = sa_sent[:score].to_f
		sa_pos = sa_sent[:count][:positive].to_f
		sa_neu = sa_sent[:count][:neutral].to_f
		sa_neg = sa_sent[:count][:negative].to_f

		#fetch tweet data
		tweet_sent = fetch_tweet_sentiment
		tweet_sent_score = tweet_sent[:score].to_f
		tweet_pos = tweet_sent[:count][:positive].to_f
		tweet_neu = tweet_sent[:count][:neutral].to_f
		tweet_neg = tweet_sent[:count][:negative].to_f

		#fetch cnbc data
		cnbc_sent = fetch_cnbc_sentiment
		cnbc_sent_score = cnbc_sent[:score].to_f
		cnbc_pos = cnbc_sent[:count][:positive].to_f
		cnbc_neu = cnbc_sent[:count][:neutral].to_f
		cnbc_neg = cnbc_sent[:count][:negative].to_f

		#fetch ycharts data
		ycharts_sent = fetch_ycharts_sentiment
		ycharts_sent_score = ycharts_sent[:score].to_f
		ycharts_pos = ycharts_sent[:count][:positive].to_f
		ycharts_neu = ycharts_sent[:count][:neutral].to_f
		ycharts_neg = ycharts_sent[:count][:negative].to_f

		#fetch forbes data
		forbes_sent = fetch_forbes_sentiment
		forbes_sent_score = forbes_sent[:score].to_f
		forbes_pos = forbes_sent[:count][:positive].to_f
		forbes_neu = forbes_sent[:count][:neutral].to_f
		forbes_neg = forbes_sent[:count][:negative].to_f

		#fetch nyt data
		nyt_sent = fetch_nyt_sentiment
		nyt_sent_score = nyt_sent[:score].to_f
		nyt_pos = nyt_sent[:count][:positive].to_f
		nyt_neu = nyt_sent[:count][:neutral].to_f
		nyt_neg = nyt_sent[:count][:negative].to_f

		media_sent_score = (nyt_sent_score + forbes_sent_score + ycharts_sent_score + cnbc_sent_score + tweet_sent_score + sa_sent_score) / 6

		pos_entries = nyt_pos + forbes_pos + ycharts_pos + cnbc_pos + tweet_pos + sa_pos
		neu_entries = nyt_neu + forbes_neu + ycharts_neu + cnbc_neu + tweet_neu + sa_neu
		neg_entries = nyt_neg + forbes_neg + ycharts_neg + cnbc_neg + tweet_neg + sa_neg

		utc_time = DateTime.now.utc
		time = utc_time.in_time_zone('Eastern Time (US & Canada)')
		self.create(date: time, dia_last: fetch_financial_data('DIA'), spy_last: fetch_financial_data('SPY'), twitter_score: tweet_sent_score, media_score: media_sent_score, investor_score: sa_sent_score, positive_entries: pos_entries,  neutral_entries: neu_entries, negative_entries: neg_entries)
	end



#charting methods

	def self.convert_database_table_to_array_to_floats(key)
		big_decimal_array = FinancialHistoryData.select(key.to_sym).map(&key.to_sym) 
		float_array = []
		big_decimal_array.each do |entry|
			float_array << entry.to_f.round(2)
		end
		float_array
	end


  def self.prepare_data_for_chart(data)
    data = FinancialHistoryData.select(data.to_sym).map(&data.to_sym) 
    data_array = []
    data.each do |entry|
    	data_array << entry.to_f
    end
    return data_array
	end


	def self.prepare_media_data_for_chart
		convert_database_table_to_array_to_floats('media_score')
	end


	def self.prepare_investor_data_for_chart
		twitter_array = convert_database_table_to_array_to_floats('twitter_score')
		sa_array = convert_database_table_to_array_to_floats('investor_score')

		investor_array = []
		i = 0
		twitter_array.each do |score|
			investor_score = (score + sa_array[i])/2
			investor_array << investor_score.round(3)
			i += 1
		end
	end


	def self.prepare_entry_dates_for_chart
		time_data = FinancialHistoryData.select(:created_at).map(&:created_at) 
		time_array = []
		time_data.each do |entry|
			time_array << entry.strftime("%m-%d-%Y, %I:%M%p")
		end
		return time_array
	end


	def self.prepare_count_data_for_pie_chart
		last = FinancialHistoryData.last
		pos = last.positive_entries.to_f
		neu = last.neutral_entries.to_f
		neg = last.negative_entries.to_f
		total = pos + neu + neg
		pos_share = (pos/total).round(3)
		neu_share = (neu/total).round(3)
		neg_share = (neg/total).round(3)
		{:positive => pos_share, :neutral => neu_share, :negative => neg_share}
	end


	def self.daily_change(open, close)
		(((close - open) / open) * 100).round(2).to_s
	end


#home page get last 24 hour data
	def self.daily_change_hash
		today = FinancialHistoryData.all.pop(8)
		daily_update = Hash.new
		daily_update[:dia] = daily_change(today.first.dia_last.to_f, today.last.dia_last.to_f).to_f.round(1)
		daily_update[:media] = daily_change(today.first.media_score.to_f, today.last.media_score.to_f).to_f.round(1)
		daily_update[:investor] = ((daily_change(today.first.investor_score.to_f, today.last.investor_score.to_f) + daily_change(today.first.twitter_score.to_f, today.last.twitter_score.to_f)).to_f / 2).to_f.round(1)
		return daily_update
	end

#sms message methods

	def self.build_message_body
		today_change = daily_change_hash
		text_body = 'Sentimyzer daily update: DIA: ' + today_change[:dia].to_s + '%, Investor: ' + today_change[:investor].to_s + '%, Media: ' + today_change[:media].to_s + '%'
		return text_body
	end


	def self.send_sms_update
  		phone_numbers = User.where(verified: true).pluck(:phone_number)
  		phone_numbers.each do |phone_number|
	  		$twilio_client.account.messages.create(
	        :from => '+16175443662',
	        :to => phone_number,
	       :body => build_message_body
	      )
	  	end
	end

end
