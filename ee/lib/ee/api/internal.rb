# frozen_string_literal: true

module EE
  module API
    module Internal
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :lfs_authentication_url
          def lfs_authentication_url(project)
            project.lfs_http_url_to_repo(params[:operation])
          end
        end
      end
    end
  end
end
