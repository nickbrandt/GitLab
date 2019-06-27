# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::ApplicationController
  include VulnerabilitiesActions

  HISTORY_RANGE = 3.months

  alias_method :vulnerable, :group

  before_action :authorize_read_group_security_dashboard!

  private

  def authorize_read_group_security_dashboard!
    render_403 unless helpers.can_read_group_security_dashboard?(group)
  end
end
