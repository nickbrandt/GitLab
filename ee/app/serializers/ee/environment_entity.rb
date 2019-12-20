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
    end

    private

    def can_read_deploy_board?
      can?(current_user, :read_deploy_board, environment.project)
    end
  end
end
