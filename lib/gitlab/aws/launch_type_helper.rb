# frozen_string_literal: true

module Gitlab
  module Aws
    class LaunchTypeHelper
      AWS_LAUNCH_TYPE_KEY = 'AUTO_DEVOPS_AWS_LAUNCH_TYPE'

      AWS_LAUNCH_TYPES = {
        ecs: 'ECS'
      }.freeze

      def initialize(project)
        @project = project
      end

      def aws_launch_type
        return unless variables

        @aws_launch_type ||= variables.find_by_key(AWS_LAUNCH_TYPE_KEY)&.value
      end

      def launch_type_valid?
        AWS_LAUNCH_TYPES.key(aws_launch_type).present?
      end

      private

      attr_reader :project

      def variables
        @variables ||= project.variables
      end
    end
  end
end
