class ChangeDefaultCourseLevel < ActiveRecord::Migration[6.0]
  def change
    change_column :courses, :level, :string, default: "All levels", null: false
  end
end
