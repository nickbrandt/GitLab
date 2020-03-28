# frozen_string_literal: true

module EE
  module Projects
    module HashedStorage
      module BaseRepositoryService
        extend ::Gitlab::Utils::Override

        attr_reader :move_design

        override :initialize
        def initialize(project:, old_disk_path:, logger: nil)
          super
          @move_design = has_design?
        end

        protected

        def has_design?
          gitlab_shell.repository_exists?(project.repository_storage, "#{old_design_disk_path}.git")
        end

        override :move_repositories
        def move_repositories
          result = super

          if move_design
            result &&= move_repository(old_design_disk_path, new_design_disk_path)
            project.clear_memoization(:design_repository)
          end

          result
        end

        override :rollback_folder_move
        def rollback_folder_move
          super

          if move_design
            move_repository(new_design_disk_path, old_design_disk_path)
          end
        end

        def design_path_suffix
          @design_path_suffix ||= EE::Gitlab::GlRepository::DESIGN.path_suffix
        end

        def old_design_disk_path
          @old_design_disk_path ||= "#{old_disk_path}#{design_path_suffix}"
        end

        def new_design_disk_path
          @new_design_disk_path ||= "#{new_disk_path}#{design_path_suffix}"
        end
      end
    end
  end
end
