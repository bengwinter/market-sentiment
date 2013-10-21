require 'yahoo_finance'
require 'pry'

class FinancialHistoryData < ActiveRecord::Base

	def fetch_nyt_news
		date = Date.today.to_s.split(/-/).join

		link_raw = 	"http://api.nytimes.com/svc/search/v2/articlesearch.json?fq=news_desk:(%22Business%22)&begin_date=" + date + "&end_date=" + date + "&api-key=dd560fd468731923ee6fcb7f2213540b:3:6136857"

		link = URI(link_raw)
		json = Net::HTTP.get(link)
		json_crack = Crack::JSON.parse(json)
		articles = json_crack["response"]["docs"]

		article_text = []

		articles.each do |article|
			text = article["lead_paragraph"].to_s + " " + article["headline"]["main"].to_s
			article_text << text
		end 

		return article_text
	end


	def nyt_sentiment_calc
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


	def fetch_nyt_sentiment
		sentiment = nyt_sentiment_calc
		sentiment.inject(0.0) { |sum, element| sum + element } / sentiment.size
	end


	def fetch_financial_data(ticker)
		quotes = YahooFinance.quotes([ticker], [:previous_close, :close], {raw: false})
		quotes.each do |quote|
			@previous_close = quote.previous_close.to_f
			@close = quote.close.to_f
			@change = ((@close - @previous_close) / @previous_close) * 100 
		end
		return @change
	end


	def update_database
		FinancialHistoryData.create(date: Date.today, djia_delta: fetch_financial_data('DIA'), sp_delta: fetch_financial_data('SPY'), twitter_score: 0.95, media_score: fetch_nyt_sentiment, investor_score: 1.2)
	end

end
