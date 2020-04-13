# frozen_string_literal: true

module EE
  module Commits
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :validate!
      def validate!
        super

        validate_repository_size!
      end

      def validate_repository_size!
        size_checker = project.repository_size_checker

        if size_checker.above_size_limit?
          raise_error(size_checker.error_message.commit_error)
        end
      end
    end
  end
end
