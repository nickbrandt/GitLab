class CreateGitlabSubscriptions < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def up
    create_table :gitlab_subscriptions, id: :bigserial do |t|
      t.timestamps_with_timezone null: false

      t.date :start_date
      t.date :end_date
      t.date :trial_ends_on

      t.references :namespace, index: { unique: true }, foreign_key: true

      t.integer :hosted_plan_id, index: true
      t.integer :max_seats_used, default: 0
      t.integer :seats, default: 0

      t.boolean :trial, default: false
    end
  end

  def down
    drop_table :gitlab_subscriptions
  end
end
