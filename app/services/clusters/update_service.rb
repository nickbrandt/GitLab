# frozen_string_literal: true

module Clusters
  class UpdateService
    attr_reader :current_user, :params

    def initialize(user = nil, params = {})
      @current_user, @params = user, params.dup
    end

    def execute(cluster)
      if validate_params(cluster)
        cluster.update(params)
      else
        false
      end
    end

    private

    def can_admin_pipeline_for_project?(project)
      Ability.allowed?(current_user, :admin_pipeline, project)
    end

    def validate_params(cluster)
      if params[:management_project_id]
        management_project = ::Project.find_by_id(params[:management_project_id])

        unless management_project
          cluster.errors.add(:management_project_id, _('Project does not exist or you don\'t have permission to perform this action'))

          return false
        end

        unless can_admin_pipeline_for_project?(management_project)
          # Use same message as not found to prevent enumeration
          cluster.errors.add(:management_project_id, _('Project does not exist or you don\'t have permission to perform this action'))

          return false
        end
      end

      true
    end
  end
end
