class AddFieldsToCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :short_description, :text
    add_column :courses, :language, :string, default: "English", null: false
    add_column :courses, :level, :string, default: "Beginner", null: false
    add_column :courses, :price, :integer, default: "0", null: false
  end
end
