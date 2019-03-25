# frozen_string_literal: true

module EE
  module EnvironmentEntity
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      expose :rollout_status, if: -> (*) { can_read_deploy_board? }, using: ::RolloutStatusEntity

      expose :logs_path, if: -> (*) { can_read_pod_logs? } do |environment|
        logs_project_environment_path(environment.project, environment)
      end
    end

    private

    def can_read_pod_logs?
      can?(current_user, :read_pod_logs, environment.project)
    end

    def can_read_deploy_board?
      can?(current_user, :read_deploy_board, environment.project)
    end
  end
end
