# frozen_string_literal: true

class LicenseManagementReportLicenseEntity < Grape::Entity
  expose :name
  expose :dependencies, using: LicenseManagementReportDependencyEntity
end
