# frozen_string_literal: true

module EE
  module LfsRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    private

    override :lfs_forbidden!
    def lfs_forbidden!
      limit_exceeded? ? render_size_error : super
    end

    override :limit_exceeded?
    def limit_exceeded?
      size_checker.above_size_limit? || objects_exceed_repo_limit?
    end

    def render_size_error
      render(
        json: {
          message: size_checker.error_message.push_error(@exceeded_limit), # rubocop:disable Gitlab/ModuleWithInstanceVariables
          documentation_url: help_url
        },
        content_type: ::LfsRequest::CONTENT_TYPE,
        status: :not_acceptable
      )
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def objects_exceed_repo_limit?
      return false unless size_checker.enabled?

      strong_memoize(:limit_exceeded) do
        lfs_push_size = objects.sum { |o| o[:size] }
        @exceeded_limit = size_checker.exceeded_size(lfs_push_size) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @exceeded_limit > 0 # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def size_checker
      project.repository_size_checker
    end
  end
end
