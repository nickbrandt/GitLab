# rubocop:disable Migration/Timestamps
class CreateLicenses < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :licenses do |t|
      t.text :data, null: false

      t.timestamps null: true
    end
  end
end
