# frozen_string_literal: true

class LicenseManagementReportLicenseEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :classification
  expose :dependencies, using: LicenseManagementReportDependencyEntity
  expose :count
  expose :url

  def classification
    default = { id: nil, name: value_for(:name), approval_status: 'unclassified' }
    found = SoftwareLicensePoliciesFinder.new(request&.current_user, request&.project, name: value_for(:name)).find
    ManagedLicenseEntity.represent(found || default)
  end
end
