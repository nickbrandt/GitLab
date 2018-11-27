class AddHeaderLogosToAppearances < ActiveRecord::Migration[4.2]
  def change
    add_column :appearances, :dark_logo, :string
    add_column :appearances, :light_logo, :string
  end
end
