module EE
  module Projects
    module EnvironmentsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_read_pod_logs!, only: [:logs]
        before_action :environment_ee, only: [:logs]
        before_action :protected_environment, only: [:terminal]
      end

      def logs
        respond_to do |format|
          format.html
          format.json do
            ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

            render json: {
              logs: pod_logs.strip.split("\n").as_json,
              pods: environment.pod_names
            }
          end
        end
      end

      private

      def environment_ee
        environment
      end

      def pod_logs
        environment.deployment_platform.read_pod_logs(params[:pod_name])
      end

      def protected_environment
        access_denied! unless can_access_environment?
      end

      def can_access_environment?
        environment.protected_deployable_by_user(current_user) && maintainer_or_admin?
      end

      def maintainer_or_admin?
        access_level >= ::Gitlab::Access::MAINTAINER || current_user.admin?
      end

      def access_level
        project.team.max_member_access(current_user.id)
      end
    end
  end
end
