class AddCounterCacheAndFriendlyIdChapters < ActiveRecord::Migration[6.0]
  def change
    add_column :chapters, :slug, :string
    add_index :chapters, :slug, unique: true

    add_column :courses, :chapters_count, :integer, null: false, default: 0
  end
end
