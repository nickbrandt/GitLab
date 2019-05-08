# frozen_string_literal: true

class Explore::OnboardingController < Explore::ApplicationController
  before_action :authenticate_user!
  before_action :set_project!

  layout 'onboarding'

  private

  def set_project!
    @project = get_onboarding_demo_project

    render_404 unless @project && can?(current_user, :read_project, @project)
  end

  def get_onboarding_demo_project
    if Gitlab.com? && Feature.enabled?(:user_onboarding)
      Project.find_by_full_path("gitlab-org/gitlab-ce")
    end
  end
end
