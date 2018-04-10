class FlushCurrentAppearanceCache < ActiveRecord::Migration
  DOWNTIME = false

  def change
    say 'Flushing `current_appearance` cache...'

    # Flush the cache for `current_appearance` as a post-deployment migration
    # to avoid old code to recache the column.
    # See https://gitlab.com/gitlab-org/gitlab-ee/issues/5571
    Rails.cache.delete('current_appearance')
  end
end
