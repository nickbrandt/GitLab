# frozen_string_literal: true

module ReviewAppSetup
  include Gitlab::Utils::StrongMemoize
  include ChecksCollaboration

  def can_setup_review_app?
    strong_memoize(:can_setup_review_app?) do
      cicd_missing? || (can_cluster_be_created? && cluster_missing?)
    end
  end

  def cicd_missing?
    current_user && can_current_user_push_code? && project.repository.gitlab_ci_yml.blank? && !project.auto_devops_enabled?
  end

  def can_cluster_be_created?
    current_user && can?(current_user, :create_cluster, project)
  end

  def can_current_user_push_code?
    strong_memoize(:can_current_user_push_code) do
      if project.empty_repo?
        can?(current_user, :push_code, project)
      else
        can_current_user_push_to_branch?(project.default_branch)
      end
    end
  end

  def cluster_missing?
    strong_memoize(:cluster_missing?) do
      project.clusters.blank?
    end
  end

  def can_current_user_push_to_branch?(branch)
    user_access(project).can_push_to_branch?(branch)
  end
end
