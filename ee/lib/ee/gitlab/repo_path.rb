# frozen_string_literal: true

module EE
  module Gitlab
    module RepoPath
      module ClassMethods
        def find_project(project_path)
          if project_alias = ProjectAlias.find_by_name(project_path)
            [project_alias.project, false]
          else
            super(project_path)
          end
        end
      end
    end
  end
end
