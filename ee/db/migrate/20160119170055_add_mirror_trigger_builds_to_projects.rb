# rubocop:disable all
class AddMirrorTriggerBuildsToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :mirror_trigger_builds, :boolean, default: false, null: false
  end
end
