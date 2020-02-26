# frozen_string_literal: true

module EE
  module EnvironmentEntity
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      expose :rollout_status, if: -> (*) { can_read_deploy_board? }, using: ::RolloutStatusEntity

      expose :project_path do |environment|
        project_path(environment.project)
      end

      expose :logs_path, if: -> (*) { can_read_pod_logs? } do |environment|
        project_logs_path(environment.project, environment_name: environment.name)
      end

      expose :logs_api_path, if: -> (*) { can_read_pod_logs? } do |environment|
        if environment.elastic_stack_available?
          elasticsearch_project_logs_path(environment.project, environment_name: environment.name, format: :json)
        else
          k8s_project_logs_path(environment.project, environment_name: environment.name, format: :json)
        end
      end

      expose :enable_advanced_logs_querying, if: -> (*) { can_read_pod_logs? } do |environment|
        environment.elastic_stack_available?
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
