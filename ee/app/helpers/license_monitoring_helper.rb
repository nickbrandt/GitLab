# frozen_string_literal: true

module LicenseMonitoringHelper
  include Gitlab::Utils::StrongMemoize

  def show_users_over_license_banner?
    current_user&.admin? && license_is_over_capacity?
  end

  private

  def license_is_over_capacity?
    return if current_license.nil? || current_license.trial?

    current_license_overage > 0
  end

  def current_license
    strong_memoize(:current_license) { License.current }
  end

  def current_license_overage
    strong_memoize(:current_license_overage) { current_license.overage_with_historical_max }
  end
end
