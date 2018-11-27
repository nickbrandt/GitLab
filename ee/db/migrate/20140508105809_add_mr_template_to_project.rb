class AddMrTemplateToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :merge_requests_template, :text
  end
end
