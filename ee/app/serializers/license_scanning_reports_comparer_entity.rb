# frozen_string_literal: true

class LicenseScanningReportsComparerEntity < Grape::Entity
  expose :new_licenses, using: LicenseScanningReportLicenseEntity
  expose :existing_licenses, using: LicenseScanningReportLicenseEntity
  expose :removed_licenses, using: LicenseScanningReportLicenseEntity
end
