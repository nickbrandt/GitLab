# frozen_string_literal: true

class AddDetectedAtToVulnerabilities < ActiveRecord::Migration[6.1]
  def change
    add_column :vulnerabilities, :detected_at, :datetime_with_timezone, default: -> { 'now()' }
  end
end
