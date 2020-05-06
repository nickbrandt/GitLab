# frozen_string_literal: true

class Projects::AlertManagementController < Projects::ApplicationController
  before_action :ensure_feature_enabled

  def index
  end

  def details
    @alert_id = params[:id]
  end

  private

  def ensure_feature_enabled
    render_404 unless Feature.enabled?(:alert_management_minimal, project)
  end
end
