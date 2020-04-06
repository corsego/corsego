class AddSlugToCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :slug, :string
    add_index :courses, :slug, unique: true
  end
end
