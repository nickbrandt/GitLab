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
      project.above_size_limit? || objects_exceed_repo_limit?
    end

    def render_size_error
      render(
        json: {
          message: ::Gitlab::RepositorySizeError.new(project).push_error(@exceeded_limit), # rubocop:disable Gitlab/ModuleWithInstanceVariables
          documentation_url: help_url
        },
        content_type: ::LfsRequest::CONTENT_TYPE,
        status: :not_acceptable
      )
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def objects_exceed_repo_limit?
      return false unless project.size_limit_enabled?

      strong_memoize(:limit_exceeded) do
        lfs_push_size = objects.sum { |o| o[:size] }
        size_with_lfs_push = project.repository_and_lfs_size + lfs_push_size

        @exceeded_limit = size_with_lfs_push - project.actual_size_limit # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @exceeded_limit > 0 # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
