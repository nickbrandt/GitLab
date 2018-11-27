class AddDoorkeeperApplicationToGeoNode < ActiveRecord::Migration[4.2]
  def change
    change_table :geo_nodes do |t|
      t.belongs_to :oauth_application
    end
  end
end
