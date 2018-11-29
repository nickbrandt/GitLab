class UpdateJenkinsServiceCategory < ActiveRecord::Migration[4.2]
  def up
    category = quote_column_name('category')
    type = quote_column_name('type')

    execute <<-EOS
UPDATE services
SET #{category} = 'ci'
WHERE #{type} IN (
  'JenkinsService',
  'JenkinsDeprecatedService'
)
EOS
  end

  def down
    # don't do anything
  end
end
