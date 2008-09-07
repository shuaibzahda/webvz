class AddActivationToUser < ActiveRecord::Migration
  def self.up
	add_column :users, :activated, :string
  end

  def self.down
	remove_column :users, :activated
  end
end
