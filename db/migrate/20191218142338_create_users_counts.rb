class CreateUsersCounts < ActiveRecord::Migration[5.2]
  def up
    execute 'SET statement_timeout = 60000;'
    create_view :users_counts, materialized: true
    add_index :users_counts, :refresh_time, unique: true
  end

  def down
    execute 'SET statement_timeout = 60000;'
    drop_view :users_counts, materialized: true
  end
end
