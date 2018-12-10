# frozen_string_literal: true

class AddReviewIdToNotes < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :notes, :review_id, :bigint
  end
end
