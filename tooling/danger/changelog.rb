# frozen_string_literal: true

require_relative 'title_linting'

module Tooling
  module Danger
    module Changelog
      NO_CHANGELOG_LABELS = [
        'tooling',
        'tooling::pipelines',
        'tooling::workflow',
        'ci-build',
        'meta'
      ].freeze
      NO_CHANGELOG_CATEGORIES = %i[docs none].freeze
      CREATE_CHANGELOG_COMMAND = 'bin/changelog -m %<mr_iid>s "%<mr_title>s"'
      CREATE_EE_CHANGELOG_COMMAND = 'bin/changelog --ee -m %<mr_iid>s "%<mr_title>s"'
      CHANGELOG_MODIFIED_URL_TEXT = "**CHANGELOG.md was edited.** Please remove the additions and create a CHANGELOG entry.\n\n"
      CHANGELOG_MISSING_URL_TEXT = "**[CHANGELOG missing](https://docs.gitlab.com/ee/development/changelog.html)**:\n\n"

      OPTIONAL_CHANGELOG_MESSAGE = <<~MSG
      If you want to create a changelog entry for GitLab FOSS, run the following:

          #{CREATE_CHANGELOG_COMMAND}

      If you want to create a changelog entry for GitLab EE, run the following instead:

          #{CREATE_EE_CHANGELOG_COMMAND}

      If this merge request [doesn't need a CHANGELOG entry](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry), feel free to ignore this message.
      MSG

      REQUIRED_CHANGELOG_REASONS = {
        db_changes: 'introduces a database migration',
        feature_flag_removed: 'removes a feature flag'
      }.freeze
      REQUIRED_CHANGELOG_MESSAGE = <<~MSG
      To create a changelog entry, run the following:

          #{CREATE_CHANGELOG_COMMAND}

      This merge request requires a changelog entry because it [%<reason>s](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry).
      MSG

      def required_reasons(feature_flag_helper: nil)
        [].tap do |reasons|
          reasons << :db_changes if git.added_files.any? { |path| path =~ %r{\Adb/(migrate|post_migrate)/} }
          reasons << :feature_flag_removed if feature_flag_helper&.respond_to?(:feature_flag_files) && feature_flag_helper.feature_flag_files(change_type: :deleted).any?
        end
      end

      def required?(feature_flag_helper: nil)
        required_reasons(feature_flag_helper: feature_flag_helper).any?
      end

      def optional?
        categories_need_changelog? && without_no_changelog_label?
      end

      def found
        @found ||= git.added_files.find { |path| path =~ %r{\A(ee/)?(changelogs/unreleased)(-ee)?/} }
      end

      def ee_changelog?
        found.start_with?('ee/')
      end

      def modified_text
        CHANGELOG_MODIFIED_URL_TEXT +
          format(OPTIONAL_CHANGELOG_MESSAGE, mr_iid: mr_iid, mr_title: sanitized_mr_title)
      end

      def required_texts(feature_flag_helper: nil)
        required_reasons(feature_flag_helper: feature_flag_helper).each_with_object({}) do |required_reason, memo|
          memo[required_reason] =
            CHANGELOG_MISSING_URL_TEXT +
              format(REQUIRED_CHANGELOG_MESSAGE, reason: REQUIRED_CHANGELOG_REASONS.fetch(required_reason), mr_iid: mr_iid, mr_title: sanitized_mr_title)
        end
      end

      def optional_text
        CHANGELOG_MISSING_URL_TEXT +
          format(OPTIONAL_CHANGELOG_MESSAGE, mr_iid: mr_iid, mr_title: sanitized_mr_title)
      end

      private

      def mr_iid
        gitlab.mr_json["iid"]
      end

      def sanitized_mr_title
        TitleLinting.sanitize_mr_title(gitlab.mr_json["title"])
      end

      def categories_need_changelog?
        (helper.changes_by_category.keys - NO_CHANGELOG_CATEGORIES).any?
      end

      def without_no_changelog_label?
        (gitlab.mr_labels & NO_CHANGELOG_LABELS).empty?
      end
    end
  end
end
