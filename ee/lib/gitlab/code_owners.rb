# frozen_string_literal: true

module Gitlab
  module CodeOwners
    FILE_NAME = 'CODEOWNERS'
    FILE_PATHS = [FILE_NAME, "docs/#{FILE_NAME}", ".gitlab/#{FILE_NAME}"].freeze

    def self.for_blob(blob)
      if blob.project.feature_available?(:code_owners)
        Loader.new(blob.project, blob.commit_id, blob.path).members
      else
        User.none
      end
    end

    # @param merge_request [MergeRequest]
    # @param merge_request_diff [MergeRequestDiff]
    #   Find code owners at a particular MergeRequestDiff.
    #   Assumed to be the most recent one if not provided.
    def self.for_merge_request(merge_request, merge_request_diff: nil)
      return [] if merge_request.source_project.nil? || merge_request.source_branch.nil?
      return [] unless merge_request.target_project.feature_available?(:code_owners)

      Loader.new(
        merge_request.target_project,
        merge_request.target_branch,
        merge_request.modified_paths(past_merge_request_diff: merge_request_diff)
      ).members.where_not_in(merge_request.author).to_a
    end
  end
end
