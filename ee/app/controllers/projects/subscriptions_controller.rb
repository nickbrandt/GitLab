# frozen_string_literal: true

class Projects::SubscriptionsController < Projects::ApplicationController
  include ::Gitlab::Utils::StrongMemoize

  before_action :authorize_admin_project!
  before_action :authorize_read_upstream_project!, only: [:create]
  before_action :feature_ci_project_subscriptions!

  def create
    subscription = project.upstream_project_subscriptions.create(upstream_project: upstream_project)

    flash[:notice] = if subscription.persisted?
                       _('Subscription successfully created.')
                     else
                       _('This project path either does not exist or is private.')
                     end

    redirect_to project_settings_ci_cd_path(project)
  end

  def destroy
    flash[:notice] = if project_subscription&.destroy
                       _('Subscription successfully deleted.')
                     else
                       _('Subscription deletion failed.')
                     end

    redirect_to project_settings_ci_cd_path(project), status: :found
  end

  private

  def upstream_project
    strong_memoize(:upstream_project) do
      Project.find_by_full_path(params[:upstream_project_path])
    end
  end

  def project_subscription
    project.upstream_project_subscriptions.find(params[:id])
  end

  def authorize_read_upstream_project!
    render_404 unless can?(current_user, :read_project, upstream_project)
  end

  def feature_ci_project_subscriptions!
    render_404 unless project.feature_available?(:ci_project_subscriptions)
  end
end
