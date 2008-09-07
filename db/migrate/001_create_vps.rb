class CreateVps < ActiveRecord::Migration
  def self.up
    create_table :vps do |t|
	t.column :cnt_id, :integer
	t.column :user_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :vps
  end
end
