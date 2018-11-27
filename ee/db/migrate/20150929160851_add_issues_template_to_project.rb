class AddIssuesTemplateToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :issues_template, :text
  end
end
