# frozen_string_literal: true

class RenameVimeoToVideoUrlInLessons < ActiveRecord::Migration[7.1]
  def change
    rename_column :lessons, :vimeo, :video_url
  end
end
