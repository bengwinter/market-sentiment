class ChangeEntriesCountColumnsToDecimals < ActiveRecord::Migration
  def change
  	change_table :financial_history_data do |t|
  	t.change :positive_entries, :decimal
  	t.change :neutral_entries, :decimal
  	t.change :negative_entries, :decimal
		end
  end
end
