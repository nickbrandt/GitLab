# frozen_string_literal: true

# Gitlab::Access module
#
# Define allowed roles that can be used
# in GitLab code to determine authorization level
#
module EE
  module Gitlab
    module Access
      extend self

      # Default project creation level
      NO_ONE_PROJECT_ACCESS = 0
      MAINTAINER_PROJECT_ACCESS = 1
      DEVELOPER_MAINTAINER_PROJECT_ACCESS = 2

      def project_creation_options
        {
          s_('ProjectCreationLevel|No one') => NO_ONE_PROJECT_ACCESS,
          s_('ProjectCreationLevel|Maintainers') => MAINTAINER_PROJECT_ACCESS,
          s_('ProjectCreationLevel|Developers + Maintainers') => DEVELOPER_MAINTAINER_PROJECT_ACCESS
        }
      end

      def level_name(name)
        project_creation_options.key(name)
      end
    end
  end
end
