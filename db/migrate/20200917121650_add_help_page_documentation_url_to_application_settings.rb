# frozen_string_literal: true

class AddHelpPageDocumentationUrlToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :help_page_documentation_url, :text
  end
end
