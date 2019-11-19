# frozen_string_literal: true

module Projects
  module Security
    class LicensesController < Projects::ApplicationController
      before_action :authorize_read_licenses_list!

      def index
        respond_to do |format|
          format.json do
            ::Gitlab::UsageDataCounters::LicensesList.count(:views)

            license_compliance = ::SCA::LicenseCompliance.new(project)
            render json: serializer.represent(
              pageable(license_compliance.policies),
              build: license_compliance.latest_build_for_default_branch
            )
          end
        end
      end

      private

      def serializer
        ::LicensesListSerializer.new(project: project, user: current_user)
          .with_pagination(request, response)
      end

      def pageable(items)
        ::Gitlab::ItemsCollection.new(items)
      end
    end
  end
end
