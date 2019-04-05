# frozen_string_literal: true

class AddInternalUrlToGeoNodes < ActiveRecord::Migration[5.0]
  def change
    add_column :geo_nodes, :internal_url, :string
  end
end
