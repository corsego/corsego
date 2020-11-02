class AddChapterReferenceToLessons < ActiveRecord::Migration[6.0]
  def change
    add_column :chapters, :lessons_count, :integer, null: false, default: 0
    add_reference :lessons, :chapter, foreign_key: true
  end
end
