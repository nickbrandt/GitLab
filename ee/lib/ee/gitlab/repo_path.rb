# frozen_string_literal: true

module EE
  module Gitlab
    module RepoPath
      module ClassMethods
        extend ::Gitlab::Utils::Override

        override :find_routes_source
        def find_routes_source(path, *args)
          return super unless License.feature_available?(:project_aliases)

          if project_alias = ProjectAlias.find_by_name(path)
            [project_alias.project, nil]
          else
            super
          end
        end
      end
    end
  end
end
