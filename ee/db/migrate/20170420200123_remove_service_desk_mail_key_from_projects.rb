# rubocop:disable Migration/RemoveColumn
class RemoveServiceDeskMailKeyFromProjects < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    remove_column :projects, :service_desk_mail_key, :string
  end
end
