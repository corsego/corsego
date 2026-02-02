# frozen_string_literal: true

class AddInvitedToEnrollments < ActiveRecord::Migration[7.1]
  def change
    add_column :enrollments, :invited, :boolean, default: false, null: false
  end
end
