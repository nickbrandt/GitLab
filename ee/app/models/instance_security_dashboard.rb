# frozen_string_literal: true

class InstanceSecurityDashboard
  extend ActiveModel::Naming

  delegate :full_path, to: :user

  def initialize(user, project_ids: [])
    @project_ids = project_ids
    @user = user
  end

  def all_pipelines
    ::Ci::Pipeline.where(project_id: users_projects_with_security_reports)
  end

  def project_ids_with_security_reports
    users_projects_with_security_reports.pluck(:project_id)
  end

  def feature_available?(feature)
    License.feature_available?(feature)
  end

  def projects
    Project.where(id: visible_users_security_dashboard_projects)
  end

  def vulnerabilities
    return Vulnerability.none if projects.empty?

    Vulnerability.for_projects(projects)
  end

  private

  attr_reader :project_ids, :user

  def users_projects_with_security_reports
    return visible_users_security_dashboard_projects if project_ids.empty?

    visible_users_security_dashboard_projects.where(project_id: project_ids)
  end

  def visible_users_security_dashboard_projects
    return users_security_dashboard_projects if user.can?(:read_all_resources)

    users_security_dashboard_projects.where('EXISTS(?)', project_authorizations)
  end

  def users_security_dashboard_projects
    UsersSecurityDashboardProject.select(:project_id).where(user: user)
  end

  def project_authorizations
    ProjectAuthorization
      .select(1)
      .where(users_security_dashboard_projects: { user_id: user.id })
      .where(project_authorizations: { user_id: user.id })
      .where('users_security_dashboard_projects.project_id = project_authorizations.project_id')
  end
end
