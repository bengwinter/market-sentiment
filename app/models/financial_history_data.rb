require 'yahoo_finance'

class FinancialHistoryData < ActiveRecord::Base

# main sentiment calculation method
	def self.sentiment_calculator(array)
		sentiment_raw = []
		sentiment_keys = []
		array.each do |entry|
			raw = $analyzer.get_score entry
			count = $analyzer.get_sentiment entry
			sentiment_raw << raw
			sentiment_keys << count
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

# fetch & find sentiment for forbes real time news feed
	def self.fetch_forbes_sentiment
		fetch_sentiment_standard_xml('http://www.forbes.com/real-time/feed2/')
	end

# fetch & find sentiment for cnbc top news feed
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

# nyt fetch & analyze 
	def self.fetch_nyt_news
		date = Date.today.to_s.split(/-/).join
		link_raw = 	"http://api.nytimes.com/svc/search/v2/articlesearch.json?fq=news_desk:(%22Business%22)&begin_date=" + date + "&end_date=" + date + "&api-key=dd560fd468731923ee6fcb7f2213540b:3:6136857"
		articles = JSON.parse(Net::HTTP.get(URI(link_raw)))["response"]["docs"]
		article_text = []
		articles.each do |article|
			text = article["headline"]["main"].to_s + ". " + article["lead_paragraph"].to_s
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
		tweets = $twitter_client.search(djia_hashtags, :count => 250, :lang => "en", :result_type => "recent").collect do |tweet|
  			tweets_array << tweet.text.to_s
  	end
  	return tweets_array
	end

	def self.fetch_tweet_sentiment
		sentiment_calculator(scrub_entries(fetch_tweets))
	end

# collect data and update database with sentiment
	def self.fetch_media_sentiment
		media = [fetch_ycharts_sentiment[:score].to_f, fetch_cnbc_sentiment[:score].to_f, fetch_forbes_sentiment[:score].to_f, fetch_nyt_sentiment[:score].to_f]
		return (media.inject(0.0) { |sum, element| sum + element } / media.length).round(3)
	end

	def self.proportion_calculator(array)
		(array.compact.inject(0.0) { |sum, element| sum + element } / array.compact.length).round(3)
	end

	def self.update_database
		media_sources = ['cnbc', 'ycharts', 'forbes', 'nyt']
		media_data = Hash.new
		media_sources.each do |source|
			media_data[source] = eval 'fetch_' + source + '_sentiment'
		end

		media_sentiment_scores = []
		media_data.each do |key, value|
			media_sentiment_scores << value[:score]
		end

		media_sentiment_score = (media_sentiment_scores.inject(0.0) { |sum, element| sum + element } / media_sentiment_scores.length).round(3)

		media_sentiment_proportions = Hash.new
		media_data.each do |key, value|
			counts = [value[:count][:positive], value[:count][:neutral], value[:count][:negative]]
			total = counts.compact.inject(0.0) { |sum, element| sum + element }
			proportions = counts.compact.map{ |x| (x / total).round(3) }
			media_sentiment_proportions[key] = {:positive => proportions[0], :neutral => proportions[1], :negative => proportions[2]}
		end

		positive_proportions = []
		neutral_proportions = []
		negative_proportions = []

		media_sentiment_proportions.each do |key, value|
			positive_proportions << value[:positive]
			neutral_proportions << value[:neutral]
			negative_proportions << value[:negative]
		end

		positive_proportion = proportion_calculator(positive_proportions)
		neutral_proportion = proportion_calculator(neutral_proportions)
		negative_proportion = proportion_calculator(negative_proportions)

		date = DateTime.now.utc.in_time_zone('Eastern Time (US & Canada)').to_s

		self.create(date: date, dia_last: fetch_financial_data('DIA'), spy_last: fetch_financial_data('SPY'), twitter_score: fetch_tweet_sentiment[:score], media_score: media_sentiment_score, investor_score: fetch_sa_sentiment[:score], positive_entries: positive_proportion, neutral_entries: neutral_proportion, negative_entries: negative_proportion)
	end

#charting methods
	def self.prepare_data(key)
		big_decimal_array = FinancialHistoryData.select(key.to_sym).map(&key.to_sym) 
		float_array = []
		big_decimal_array.each do |entry|
			float_array << entry.to_f.round(2)
		end
		float_array
	end

	def self.prepare_media_data_for_chart
		prepare_data('media_score')
	end

	def self.prepare_investor_data_for_chart
		twitter_array = prepare_data('twitter_score')
		sa_array = prepare_data('investor_score')
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
		{:positive => last.positive_entries.to_f, :neutral => last.neutral_entries.to_f, :negative => last.negative_entries.to_f}
	end

#home page get last 24 hour data
	def self.daily_change(open, close)
		(((close - open) / open.abs) * 100).round(2).to_s
	end

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
			User.send_text('+16175443662', phone_number, build_message_body)
  	end
	end

end