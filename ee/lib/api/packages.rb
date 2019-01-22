# frozen_string_literal: true

module API
  class Packages < Grape::API
    include PaginationParams

    before do
      require_packages_enabled!
      authorize_packages_feature!
      authorize_download_package!
    end

    helpers ::API::Helpers::PackagesHelpers

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all project packages' do
        success EE::API::Entities::Package
      end
      params do
        use :pagination
      end
      get ':id/packages' do
        packages = user_project.packages

        present paginate(packages), with: EE::API::Entities::Package
      end
    end
  end
end
