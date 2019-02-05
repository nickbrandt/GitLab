# frozen_string_literal: true

module Gitlab
  module CodeOwners
    FILE_NAME = 'CODEOWNERS'
    FILE_PATHS = [FILE_NAME, "docs/#{FILE_NAME}", ".gitlab/#{FILE_NAME}"].freeze

    def self.for_blob(blob)
      if blob.project.feature_available?(:code_owners)
        Loader.new(blob.project, blob.commit_id, blob.path).members
      else
        []
      end
    end

    # @param merge_request [MergeRequest]
    # @param merge_request_diff [MergeRequestDiff]
    #   Find code owners entries at a particular MergeRequestDiff.
    #   Assumed to be the most recent one if not provided.
    def self.entries_for_merge_request(merge_request, merge_request_diff: nil)
      loader_for_merge_request(merge_request, merge_request_diff)&.entries || []
    end

    def self.for_merge_request(merge_request, merge_request_diff: nil)
      loader = loader_for_merge_request(merge_request, merge_request_diff)
      return [] unless loader

      loader.members.reject { |owner| owner == merge_request.author }
    end

    def self.loader_for_merge_request(merge_request, merge_request_diff)
      return if merge_request.source_project.nil? || merge_request.source_branch.nil?
      return unless merge_request.target_project.feature_available?(:code_owners)

      Loader.new(
        merge_request.target_project,
        merge_request.target_branch,
        merge_request.modified_paths(past_merge_request_diff: merge_request_diff)
      )
    end
    private_class_method :loader_for_merge_request
  end
end
