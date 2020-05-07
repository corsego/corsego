class AddBalanceFieldsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :balance, :integer, default: 0, null: false
    add_column :users, :course_income, :integer, default: 0, null: false
    add_column :users, :enrollment_expences, :integer, default: 0, null: false
  end
end
