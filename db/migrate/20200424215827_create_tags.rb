class CreateTags < ActiveRecord::Migration[6.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.integer :course_tags_count, null: false, default: 0
    end
  end
end
