# frozen_string_literal: true

class AddGroupViewToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :group_view, :integer
  end
end
