class AddPosNeuNegColumnsToFinancialHistoryData < ActiveRecord::Migration
  def change
  	change_table :financial_history_data do |t|
  	t.integer :positive_entries
  	t.integer :neutral_entries
  	t.integer :negative_entries
end
  end
end
