# frozen_string_literal: true

class Projects::Quality::TestCasesController < Projects::ApplicationController
  before_action :check_quality_management_available!
  before_action :authorize_read_issue!
  before_action :verify_test_cases_flag!
  before_action do
    push_frontend_feature_flag(:quality_test_cases, project)
  end

  def index
    respond_to do |format|
      format.html
    end
  end

  private

  def verify_test_cases_flag!
    render_404 unless Feature.enabled?(:quality_test_cases, project)
  end
end
