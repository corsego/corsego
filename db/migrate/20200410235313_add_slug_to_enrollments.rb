class AddSlugToEnrollments < ActiveRecord::Migration[6.0]
  def change
    add_column :enrollments, :slug, :string
    add_index :enrollments, :slug, unique: true
  end
end
