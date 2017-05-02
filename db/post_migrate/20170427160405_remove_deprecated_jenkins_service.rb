class RemoveDeprecatedJenkinsService < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute <<-SQL
      DELETE FROM services WHERE type = 'JenkinsDeprecatedService';
    SQL
  end

  def down
  end
end
