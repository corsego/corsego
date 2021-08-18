class AddCachedVotesToComments < ActiveRecord::Migration[6.1]
  def change
    change_table :comments do |t|
      t.integer :cached_votes_total, default: 0
      t.integer :cached_votes_up, default: 0
      t.integer :cached_votes_down, default: 0
    end

  end
end
