# frozen_string_literal: true

class Profiles::PipelineQuotaController < Profiles::ApplicationController
  def index
    return redirect_to(profile_usage_quotas_path) if Feature.enabled?(:user_usage_quota)

    @namespace = current_user.namespace
    @projects = @namespace.projects.with_shared_runners_limit_enabled.page(params[:page])
  end
end
