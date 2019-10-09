# frozen_string_literal: true

module Ci
  class CompareLicenseScanningReportsService < ::Ci::CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::LicenseScanning::ReportsComparer
    end

    def serializer_class
      LicenseScanningReportsComparerSerializer
    end

    def get_report(pipeline)
      pipeline&.license_scanning_report
    end
  end
end
