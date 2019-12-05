# frozen_string_literal: true

class LicenseScanningReportLicenseEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :classification
  expose :dependencies, using: LicenseScanningReportDependencyEntity
  expose :count
  expose :url

  def classification
    default = { id: nil, name: value_for(:name), classification: 'unclassified' }
    found = SoftwareLicensePoliciesFinder.new(request&.current_user, request&.project, name: value_for(:name)).find
    ManagedLicenseEntity.represent(found || default)
  end
end
