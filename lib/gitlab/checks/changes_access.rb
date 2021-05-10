# frozen_string_literal: true

module Gitlab
  module Checks
    class ChangesAccess
      ATTRIBUTES = %i[user_access project protocol changes logger].freeze

      attr_reader(*ATTRIBUTES)

      def initialize(
        changes, user_access:, project:, protocol:, logger:
      )
        @changes = changes
        @user_access = user_access
        @project = project
        @protocol = protocol
        @logger = logger
      end

      def validate!
        logger.log_timed("Running checks for #{changes.length} changes") do
          bulk_access_checks!
        end

        true
      end

      protected

      def bulk_access_checks!
      end
    end
  end
end
