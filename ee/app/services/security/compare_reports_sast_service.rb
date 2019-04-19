# frozen_string_literal: true

module Security
  class CompareReportsSastService < CompareReportsBaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :project

    def initialize(base_report, head_report, project)
      @project = project
      super(base_report, head_report)
    end

    private

    # Update location for base report occurrences by leveraging the git diff
    def update_base_occurrence_locations
      return unless git_diff

      # Group by file path to optimize the usage of Diff::File and Diff::LineMapper
      base_report.occurrences.group_by(&:file_path).each do |file_path, occurrences|
        update_locations_by_file(git_diff, file_path, occurrences)
      end
    end

    def update_locations_by_file(git_diff, file_path, occurrences)
      diff_file = git_diff.diff_file_with_old_path(file_path)

      return if diff_file.nil? || diff_file.deleted_file?

      update_locations(diff_file, occurrences)
    end

    def update_locations(diff_file, occurrences)
      line_mapper = Gitlab::Diff::LineMapper.new(diff_file)

      occurrences.each do |occurrence|
        new_path = line_mapper.diff_file.new_path
        new_start_line = line_mapper.old_to_new(occurrence.start_line)
        new_end_line = occurrence.end_line.present? ? line_mapper.old_to_new(occurrence.end_line) : nil

        # skip if the line has been removed
        # NB: if the line's content has changed it will be nil too
        next if new_start_line.nil?

        new_location = Gitlab::Ci::Reports::Security::Locations::Sast.new(
          file_path: new_path,
          start_line: new_start_line,
          end_line: new_end_line
        )
        occurrence.update_location(new_location)
      end
    end

    def git_diff
      strong_memoize(:git_diff) do
        compare = CompareService.new(project, head_report.commit_sha).execute(project, base_report.commit_sha, straight: false)
        next unless compare

        compare.diffs(expanded: true)
      end
    end
  end
end
