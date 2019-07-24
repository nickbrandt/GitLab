# frozen_string_literal: true

module Gitlab
  # Preloading of Vulnerabilities Occurrences.
  #
  # This class can be used to efficiently preload the feedback of a given list of
  # vulnerabilities (occurrences).
  module Vulnerabilities
    class OccurrencesPreloader
      def self.preload!(occurrences)
        occurrences.all_preloaded.tap do |occurrences|
          preload_feedback!(occurrences)
        end
      end

      def self.preload_feedback!(occurrences)
        occurrences.each do |occurrence|
          occurrence.dismissal_feedback
          occurrence.issue_feedback
          occurrence.merge_request_feedback
        end
      end
    end
  end
end
