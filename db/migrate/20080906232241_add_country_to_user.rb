class AddCountryToUser < ActiveRecord::Migration
  def self.up
	add_column :users, :country, :string
  end

  def self.down
	remove_column :users, :country
  end
end
