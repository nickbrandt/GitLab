class AddHeaderAndFooterBannersToAppearancesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :appearances, :header_message, :text
    add_column :appearances, :header_message_html, :text

    add_column :appearances, :footer_message, :text
    add_column :appearances, :footer_message_html, :text

    add_column :appearances, :message_background_color, :text
    add_column :appearances, :message_font_color, :text

    say 'Flushing `current_appearance` cache...'

    # Flush the cache for `current_appearance` right after the migration
    # See https://gitlab.com/gitlab-org/gitlab-ee/issues/5571
    Rails.cache.delete('current_appearance')
  end
end
