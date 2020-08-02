class RenameCoursesShortDescriptionToMarketingDescription < ActiveRecord::Migration[6.0]
  def change
    rename_column :courses, :short_description, :marketing_description
  end
end
