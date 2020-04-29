class RemoveActiveStorageUpdate < ActiveRecord::Migration[6.0]
  def change
    remove_column :active_storage_blobs, :service_name
    drop_table :active_storage_variant_records
  end
end
