# frozen_string_literal: true

class Projects::TracingsController < Projects::ApplicationController
  content_security_policy do |p|
    next if p.directives.blank?

    p.frame_src("*")
  end

  before_action :check_license
  before_action :authorize_update_environment!

  def show
  end

  private

  def check_license
    render_404 unless @project.feature_available?(:tracing, current_user)
  end
end
