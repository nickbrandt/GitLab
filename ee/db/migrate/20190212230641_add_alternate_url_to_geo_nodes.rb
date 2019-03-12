# frozen_string_literal: true

class AddAlternateUrlToGeoNodes < ActiveRecord::Migration[5.0]
  def change
    add_column :geo_nodes, :alternate_url, :string
  end
end
