# frozen_string_literal: true

class Projects::ClustersController < Clusters::ClustersController
<<<<<<< HEAD
  prepend EE::Projects::ClustersController

  include ProjectUnauthorized

  prepend_before_action :project
  before_action :repository

=======
  include ProjectUnauthorized

  prepend_before_action :project
  before_action :repository

>>>>>>> upstream/master
  layout 'project'

  private

  def clusterable
    @clusterable ||= ClusterablePresenter.fabricate(project, current_user: current_user)
  end

  def project
    @project ||= find_routable!(Project, File.join(params[:namespace_id], params[:project_id]), not_found_or_authorized_proc: project_unauthorized_proc)
  end

  def repository
    @repository ||= project.repository
  end
end
