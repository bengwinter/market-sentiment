class AddVerifiedColumnToUserTable < ActiveRecord::Migration
  def change
  	change_table :users do |t|
  	t.boolean :verified, default: false
	end
  end
end
