class HelpTextToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :help_text, :text
  end
end
