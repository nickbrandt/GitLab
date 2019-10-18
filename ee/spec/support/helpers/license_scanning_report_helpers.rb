# frozen_string_literal: true

module LicenseScanningReportHelpers
  def all_dependency_paths(report)
    report.licenses.map { |license| license.dependencies.map(&:path) }.flatten.compact
  end

  def dependency_by_name(license, name)
    license.dependencies.find { |dep| dep.name == name }
  end

  def find_license_by_name(licenses, name)
    licenses.find { |license| license.name == name }
  end
end
