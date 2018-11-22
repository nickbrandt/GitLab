class AddSystemHookToGeoNode < ActiveRecord::Migration[4.2]
  def change
    change_table :geo_nodes do |t|
      t.references :system_hook
    end
  end
end
