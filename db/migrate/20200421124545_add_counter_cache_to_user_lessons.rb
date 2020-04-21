class AddCounterCacheToUserLessons < ActiveRecord::Migration[6.0]
  def change
    add_column :lessons, :user_lessons_count, :integer, null: false, default: 0
    add_column :users, :user_lessons_count, :integer, null: false, default: 0
  end
end
