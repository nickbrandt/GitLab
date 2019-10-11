# frozen_string_literal: true

class ImportSoftwareLicensesWorker
  include ApplicationWorker

  queue_namespace :cronjob

  def perform
    catalogue.each do |spdx_license|
      if unknown_licenses[spdx_license.name]
        unknown_licenses_with(spdx_license.name)
          .update_all(spdx_identifier: spdx_license.id)
      else
        SoftwareLicense.safe_find_or_create_by!(
          name: spdx_license.name,
          spdx_identifier: spdx_license.id
        )
      end
    end
  end

  private

  def unknown_licenses
    @unknown_licenses ||=
      unknown_licenses_with(catalogue.map(&:name)).grouped_by_name.count
  end

  def unknown_licenses_with(name)
    SoftwareLicense.unknown.by_name(name)
  end

  def catalogue
    @catalogue ||= Gitlab::SPDX::Catalogue.latest
  end
end
