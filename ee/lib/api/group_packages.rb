# frozen_string_literal: true

module API
  class GroupPackages < Grape::API
    include PaginationParams

    before do
      authorize_packages_access!(user_group)
    end

    helpers ::API::Helpers::PackagesHelpers

    params do
      requires :id, type: String, desc: "Group's ID or path"
      optional :exclude_subgroups, type: Boolean, default: false, desc: 'Determines if subgroups should be excluded'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all project packages within a group' do
        detail 'This feature was introduced in GitLab 12.5'
        success EE::API::Entities::Package
      end
      params do
        use :pagination
      end
      get ':id/packages' do
        packages = Packages::GroupPackagesFinder.new(
          current_user,
          user_group,
          exclude_subgroups: params[:exclude_subgroups]
        ).execute

        present paginate(packages), with: EE::API::Entities::Package, user: current_user, group: true
      end
    end
  end
end
