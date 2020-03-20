# frozen_string_literal: true

module EE
  module API
    module Entities
      module Todo
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        override :todo_target_class
        def todo_target_class(target_type)
          super
        rescue NameError
          # false as second argument prevents looking up in module hierarchy
          # see also https://gitlab.com/gitlab-org/gitlab-foss/issues/59719
          ::EE::API::Entities.const_get(target_type, false)
        end

        override :todo_target_url
        def todo_target_url(todo)
          return super unless todo.target_type == ::DesignManagement::Design.name

          design = todo.target
          path_options = {
            anchor: todo_target_anchor(todo),
            vueroute: design.filename
          }

          ::Gitlab::Routing.url_helpers.designs_project_issue_url(design.project, design.issue, path_options)
        end
      end
    end
  end
end
