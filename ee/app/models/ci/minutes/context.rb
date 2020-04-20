# frozen_string_literal: true

module Ci
  module Minutes
    class Context
      attr_reader :namespace, :level

      delegate :full_path, to: :level

      def initialize(project, namespace)
        @project = project
        @namespace = project&.shared_runners_limit_namespace || namespace
        @level = project || namespace
      end

      private

      attr_reader :project
    end
  end
end
