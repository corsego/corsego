# frozen_string_literal: true

class AddInviteFieldsToCourses < ActiveRecord::Migration[7.1]
  def change
    add_column :courses, :invite_token, :string
    add_column :courses, :invite_enabled, :boolean, default: false, null: false
    add_index :courses, :invite_token, unique: true
  end
end
