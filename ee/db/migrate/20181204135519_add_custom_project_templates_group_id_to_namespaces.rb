# frozen_string_literal: true

class AddCustomProjectTemplatesGroupIdToNamespaces < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :namespaces, :custom_project_templates_group_id, :integer
  end
end
