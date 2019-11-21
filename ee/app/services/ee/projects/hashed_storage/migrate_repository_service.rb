# frozen_string_literal: true

module EE
  module Projects
    module HashedStorage
      module MigrateRepositoryService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          super do
            ::Geo::HashedStorageMigratedEventStore.new(
              project,
              old_storage_version: old_storage_version,
              old_disk_path: old_disk_path,
              old_wiki_disk_path: old_wiki_disk_path
            ).create!
          end
        end

        private

        override :move_repositories
        def move_repositories
          result = super

          if move_design
            result &&= move_repository("#{old_disk_path}.design", "#{new_disk_path}.design")
          end

          result
        end
      end
    end
  end
end
