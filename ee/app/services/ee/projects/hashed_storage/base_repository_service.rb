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
          gitlab_shell.repository_exists?(project.repository_storage, "#{old_disk_path}.design.git")
        end

        override :move_repositories
        def move_repositories
          result = super

          if move_design
            result &&= move_repository("#{old_disk_path}.design", "#{new_disk_path}.design")
          end

          result
        end

        override :rollback_folder_move
        def rollback_folder_move
          super

          if move_design
            move_repository("#{new_disk_path}.design", "#{old_disk_path}.design")
          end
        end
      end
    end
  end
end
