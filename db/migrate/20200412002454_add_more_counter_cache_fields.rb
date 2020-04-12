class AddMoreCounterCacheFields < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :lessons_count, :integer, null: false, default: 0
    add_column :users, :courses_count, :integer, null: false, default: 0
    add_column :users, :enrollments_count, :integer, null: false, default: 0
  end
end
