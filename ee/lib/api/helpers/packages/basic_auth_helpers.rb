# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module BasicAuthHelpers
        module Constants
          AUTHENTICATE_REALM_HEADER = 'Www-Authenticate: Basic realm'
          AUTHENTICATE_REALM_NAME = 'GitLab Packages Registry'
        end

        include Constants

        def find_personal_access_token
          find_personal_access_token_from_http_basic_auth
        end

        def authorized_user_project
          @authorized_user_project ||= authorized_project_find!(params[:id])
        end

        def authorized_project_find!(id)
          project = find_project(id)

          unless project && can?(current_user, :read_project, project)
            return unauthorized_or! { not_found! }
          end

          project
        end

        def authorize!(action, subject = :global, reason = nil)
          return if can?(current_user, action, subject)

          unauthorized_or! { forbidden!(reason) }
        end

        def unauthorized_or!
          current_user ? yield : unauthorized_with_header!
        end

        def unauthorized_with_header!
          header(AUTHENTICATE_REALM_HEADER, AUTHENTICATE_REALM_NAME)
          unauthorized!
        end
      end
    end
  end
end
