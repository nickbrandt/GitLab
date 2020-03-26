# frozen_string_literal: true

class AddSquashOptionToProject < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :projects, :squash_option, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :projects, :squash_option
    end
  end
end
