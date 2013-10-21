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
		link = URI("http://seekingalpha.com/listing/most-popular-articles.xml")
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


	def self.update_database
		nyt_sentiment = fetch_nyt_sentiment.to_f
		self.create(date: DateTime.now, dia_last: fetch_financial_data('DIA'), spy_last: fetch_financial_data('SPY'), twitter_score: 0.95, media_score: nyt_sentiment, investor_score: fetch_sa_sentiment)
	end

end
