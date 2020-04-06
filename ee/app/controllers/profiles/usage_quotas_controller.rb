# frozen_string_literal: true

class Profiles::UsageQuotasController < Profiles::ApplicationController
  def index
    return redirect_to(profile_pipeline_quota_path) if Feature.disabled?(:user_usage_quota)

    @namespace = current_user.namespace
    @projects = @namespace.projects.with_shared_runners_limit_enabled.page(params[:page])
  end
end
