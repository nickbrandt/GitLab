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
        return if changes.empty?

        single_access_checks!

        logger.log_timed("Running checks for #{changes.length} changes") do
          bulk_access_checks!
        end

        true
      end

      protected

      def single_access_checks!
        # Iterate over all changes to find if user allowed all of them to be applied
        changes.each.with_index do |change, index|
          skip_lfs_integrity_check = index != 0

          # If user does not have access to make at least one change, cancel all
          # push by allowing the exception to bubble up
          Checks::SingleChangeAccess.new(
            change,
            user_access: user_access,
            project: project,
            skip_lfs_integrity_check: skip_lfs_integrity_check,
            protocol: protocol,
            logger: logger
          ).validate!
        end
      end

      def bulk_access_checks!
      end
    end
  end
end
