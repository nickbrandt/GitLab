# frozen_string_literal: true

class AddExtraSharedRunnersMinutesLimitToNamespaces < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :namespaces, :extra_shared_runners_minutes_limit, :integer
  end
end
