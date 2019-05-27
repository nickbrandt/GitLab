# frozen_string_literal: true

class Groups::UsageQuotasController < Groups::ApplicationController
  before_action :authorize_admin_group!
  before_action :validate_shared_runner_minutes_support!

  layout 'group_settings'

  def index
    @projects = @group.all_projects.with_shared_runners_limit_enabled.page(params[:page])
  end

  private

  def validate_shared_runner_minutes_support!
    render_404 unless @group.shared_runner_minutes_supported?
  end
end
