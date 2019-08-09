# frozen_string_literal: true

class LicenseManagementReportLicenseEntity < Grape::Entity
  expose :name
  expose :dependencies, using: LicenseManagementReportDependencyEntity
  expose :count do |license|
    license.dependencies.size
  end

  def self.licenses_payload(report)
    report.licenses.empty? ? {} : self.represent(report.licenses).as_json
  end
end
