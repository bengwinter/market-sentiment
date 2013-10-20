class CreateFinancialHistoryData < ActiveRecord::Migration
  def change
    create_table :financial_history_data do |t|
      t.date :date
      t.decimal :djia_delta
      t.decimal :sp_delta
      t.decimal :twitter_score
      t.decimal :media_score
      t.decimal :investor_score
      t.timestamps
    end
  end
end
