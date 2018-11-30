class RenameJenkinsService < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE services SET type = 'JenkinsDeprecatedService' WHERE type = 'JenkinsService';"
  end

  def down
    execute "UPDATE services SET type = 'JenkinsService' WHERE type = 'JenkinsDeprecatedService';"
  end
end
