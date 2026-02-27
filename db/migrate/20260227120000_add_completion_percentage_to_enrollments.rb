# frozen_string_literal: true

class AddCompletionPercentageToEnrollments < ActiveRecord::Migration[8.1]
  def up
    add_column :enrollments, :completion_percentage, :float, default: 0, null: false

    # Backfill all existing enrollments with their current completion progress.
    # For each enrollment, calculate: (completed lessons / total lessons) * 100
    execute <<-SQL.squish
      UPDATE enrollments
      SET completion_percentage = subquery.percentage
      FROM (
        SELECT
          e.id AS enrollment_id,
          CASE
            WHEN c.lessons_count = 0 THEN 0
            ELSE (COUNT(ul.id)::float / c.lessons_count) * 100
          END AS percentage
        FROM enrollments e
        INNER JOIN courses c ON c.id = e.course_id
        LEFT JOIN lessons l ON l.course_id = c.id
        LEFT JOIN user_lessons ul ON ul.lesson_id = l.id AND ul.user_id = e.user_id
        GROUP BY e.id, c.lessons_count
      ) AS subquery
      WHERE enrollments.id = subquery.enrollment_id
    SQL
  end

  def down
    remove_column :enrollments, :completion_percentage
  end
end
