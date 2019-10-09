# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::ApplicationController
  include SecurityDashboardsPermissions
  include VulnerabilityFindingsActions

  alias_method :vulnerable, :group

  def history
    history_count = Gitlab::Vulnerabilities::History.new(group, filter_params).vulnerabilities_counter

    respond_to do |format|
      format.json do
        render json: history_count
      end
    end
  end
end
