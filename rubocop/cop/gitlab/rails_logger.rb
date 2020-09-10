# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      class RailsLogger < ::RuboCop::Cop::Cop
        include CodeReuseHelpers

        # This cop checks for the Rails.logger in the codebase
        #
        # @example
        #
        #   # bad
        #   Rails.logger.error("Project #{project.full_path} could not be saved")
        #
        #   # good
        #   Gitlab::AppLogger.error("Project %{project_path} could not be saved" % { project_path: project.full_path })
        MSG = 'Use a structured JSON logger instead of `Rails.logger`. ' \
          'https://docs.gitlab.com/ee/development/logging.html'.freeze

        def_node_matcher :rails_logger?, <<~PATTERN
          (send (const nil? :Rails) :logger ... )
        PATTERN

        def on_send(node)
          return unless rails_logger?(node)

          add_offense(node, location: :expression)
        end
      end
    end
  end
end
