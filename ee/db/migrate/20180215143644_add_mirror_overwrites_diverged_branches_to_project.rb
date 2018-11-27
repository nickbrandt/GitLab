class AddMirrorOverwritesDivergedBranchesToProject < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :projects, :mirror_overwrites_diverged_branches, :boolean
  end
end
