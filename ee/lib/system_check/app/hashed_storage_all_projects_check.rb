# frozen_string_literal: true

module SystemCheck
  module App
    class HashedStorageAllProjectsCheck < SystemCheck::BaseCheck
      set_name 'All projects are in hashed storage?'

      def check?
        !Project.with_unmigrated_storage.exists?
      end

      def show_error
        try_fixing_it(
          "Please migrate all projects to hashed storage#{' on the primary' if Gitlab::Geo.secondary?}",
          "to avoid security issues and ensure data integrity."
        )

        for_more_information('doc/administration/repository_storage_types.md')
      end
    end
  end
end
