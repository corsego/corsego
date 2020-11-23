class AddTemporaryVimeoIdToLessons < ActiveRecord::Migration[6.0]
  def change
    add_column :lessons, :vimeo, :string
  end
end
