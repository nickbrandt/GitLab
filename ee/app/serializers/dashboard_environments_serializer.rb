# frozen_string_literal: true

class DashboardEnvironmentsSerializer < BaseSerializer
  entity DashboardEnvironmentsProjectEntity

  def represent(projects_with_folders, opts = {}, entity_class = nil)
    projects_with_folders.map do |project, folders|
      super(project, opts.merge(folders: folders), entity_class)
    end
  end
end
