class CreateFinancialHistoryData < ActiveRecord::Migration
  def change
    create_table :financial_history_data do |t|
	   	t.date     "date"
	    t.decimal  "dia_last"
	    t.decimal  "spy_last"
	    t.decimal  "twitter_score"
	    t.decimal  "media_score"
	    t.decimal  "investor_score"
	    t.timestamps
    end
  end
end
