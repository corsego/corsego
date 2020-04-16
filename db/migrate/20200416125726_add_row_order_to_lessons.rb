class AddRowOrderToLessons < ActiveRecord::Migration[6.0]
  def change
    add_column :lessons, :row_order, :integer
  end
end
