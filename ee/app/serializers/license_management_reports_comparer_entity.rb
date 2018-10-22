# frozen_string_literal: true

class LicenseManagementReportsComparerEntity < Grape::Entity
  expose :new_licenses, using: LicenseManagementReportLicenseEntity
  expose :existing_licenses, using: LicenseManagementReportLicenseEntity
  expose :removed_licenses, using: LicenseManagementReportLicenseEntity
end
