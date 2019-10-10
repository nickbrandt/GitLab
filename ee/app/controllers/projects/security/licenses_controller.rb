# frozen_string_literal: true

module Projects
  module Security
    class LicensesController < Projects::ApplicationController
      before_action :authorize_read_licenses_list!

      def index
        respond_to do |format|
          format.json do
            ::Gitlab::UsageDataCounters::LicensesList.count(:views)

            render json: serializer.represent(licenses, build: report_service.build)
          end
        end
      end

      private

      def licenses
        found_licenses = report_service.able_to_fetch? ? service.execute : []

        ::Gitlab::ItemsCollection.new(found_licenses)
      end

      def report_service
        @report_service ||= ::Security::ReportFetchService.new(project, ::Ci::JobArtifact.license_management_reports)
      end

      def serializer
        ::LicensesListSerializer.new(project: project, user: current_user)
          .with_pagination(request, response)
      end

      def service
        ::Security::LicensesListService.new(pipeline: report_service.pipeline)
      end
    end
  end
end
