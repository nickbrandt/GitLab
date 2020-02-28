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
        optional :order_by, type: String, values: %w[created_at name version type], default: 'created_at',
                            desc: 'Return packages ordered by `created_at`, `name`, `version` or `type` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'asc',
                        desc: 'Return packages sorted in `asc` or `desc` order.'
      end
      get ':id/packages' do
        packages = Packages::GroupPackagesFinder.new(
          current_user,
          user_group,
          exclude_subgroups: params[:exclude_subgroups],
          order_by: params[:order_by],
          sort: params[:sort]
        ).execute

        present paginate(packages), with: EE::API::Entities::Package, user: current_user, group: true
      end
    end
  end
end
