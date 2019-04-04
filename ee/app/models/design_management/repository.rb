# frozen_string_literal: true

module DesignManagement
  class Repository < ::Repository
    def initialize(project)
      full_path = project.full_path + EE::Gitlab::GlRepository::DESIGN.path_suffix
      disk_path = project.disk_path + EE::Gitlab::GlRepository::DESIGN.path_suffix

      super(full_path, project, disk_path: disk_path, repo_type: EE::Gitlab::GlRepository::DESIGN)
    end
  end
end
