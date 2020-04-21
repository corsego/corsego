class AddCounterCacheComments < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :comments_count, :integer, null: false, default: 0
    add_column :lessons, :comments_count, :integer, null: false, default: 0
  end
end
