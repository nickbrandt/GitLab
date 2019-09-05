# frozen_string_literal: true

module Ci
  class CompareLicenseManagementReportsService < ::Ci::CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::LicenseManagement::ReportsComparer
    end

    def serializer_class
      LicenseManagementReportsComparerSerializer
    end

    def serializer_params
      { project: project, current_user: current_user }
    end

    def get_report(pipeline)
      pipeline&.license_management_report
    end
  end
end
