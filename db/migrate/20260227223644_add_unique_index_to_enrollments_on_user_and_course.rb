class AddUniqueIndexToEnrollmentsOnUserAndCourse < ActiveRecord::Migration[8.1]
  def change
    # Remove the individual user_id index — the composite index covers user_id lookups (leftmost column).
    # Keep course_id index — the composite index does NOT cover course_id-only lookups.
    remove_index :enrollments, :user_id, if_exists: true

    add_index :enrollments, [:user_id, :course_id], unique: true
  end
end
