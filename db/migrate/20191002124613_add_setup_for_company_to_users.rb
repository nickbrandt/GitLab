# frozen_string_literal: true

class AddSetupForCompanyToUsers < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :users, :setup_for_company, :boolean
  end
end
