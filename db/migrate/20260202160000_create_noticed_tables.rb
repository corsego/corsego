# frozen_string_literal: true

class CreateNoticedTables < ActiveRecord::Migration[7.1]
  def change
    create_table :noticed_events do |t|
      t.string :type
      t.belongs_to :record, polymorphic: true
      t.jsonb :params
      t.timestamps
    end

    create_table :noticed_notifications do |t|
      t.string :type
      t.belongs_to :event, null: false, foreign_key: { to_table: :noticed_events }
      t.belongs_to :recipient, polymorphic: true, null: false
      t.datetime :read_at
      t.datetime :seen_at
      t.timestamps
    end
  end
end
