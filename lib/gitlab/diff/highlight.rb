# frozen_string_literal: true

module Gitlab
  module Diff
    class Highlight
      def initialize(diff_lines, repository: nil)
        @repository = repository
        @project = repository&.project

        if diff_lines.is_a?(Gitlab::Diff::File)
          @diff_file = diff_lines
          @diff_lines = @diff_file.diff_lines
          @syntax_highlight = SyntaxHighlight.new(@diff_file)
        else
          @diff_lines = diff_lines
        end

        @raw_lines = @diff_lines.map(&:text)
      end

      def highlight
        @diff_lines.map do |diff_line|
          diff_line = diff_line.dup
          # ignore highlighting for "match" lines
          next diff_line if diff_line.meta?

          apply_syntax_highlight(diff_line)
          apply_diff_highlight(diff_line)

          diff_line
        end
      end

      private

      attr_reader :diff_file, :diff_lines, :raw_lines, :syntax_highlight, :repository, :project

      def apply_syntax_highlight(diff_line)
        diff_line.rich_text =
          if diff_file && diff_file.diff_refs
            syntax_highlight.highlight(diff_line)
          else
            ERB::Util.html_escape(diff_line.text)
          end
      end

      def apply_diff_highlight(diff_line)
        line_inline_diffs = inline_diffs[diff_line.index]

        return unless line_inline_diffs

        diff_line.rich_text = InlineDiffMarker.new(diff_line.text, diff_line.rich_text).mark(line_inline_diffs)
      rescue RangeError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/45441')
      end

      def inline_diffs
        @inline_diffs ||= InlineDiff.for_lines(@raw_lines, project: project)
      end
    end
  end
end
