class AddCounterCacheToModels < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :enrollments_count, :integer, null: false, default: 0
  end
end
