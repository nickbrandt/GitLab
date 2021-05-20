# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDecryptableToLicenses < ActiveRecord::Migration[6.0]
  def change
    add_column :licenses, :decryptable, :boolean, default: true
  end
end
