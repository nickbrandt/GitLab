# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportPullRequestReviewWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      tags :exclude_from_kubernetes

      def representation_class
        Gitlab::GithubImport::Representation::PullRequestReview
      end

      def importer_class
        Importer::PullRequestReviewImporter
      end

      def object_type
        :pull_request_review
      end

      def counter_name
        :github_importer_imported_pull_request_reviews
      end

      def counter_description
        'The number of imported GitHub pull request reviews'
      end
    end
  end
end
