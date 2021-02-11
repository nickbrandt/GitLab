# frozen_string_literal: true

module Gitlab
  module WordDiff
    class Highlight
      attr_reader :diff_file, :diff_lines, :raw_lines, :repository

      delegate :old_path, :new_path, :old_sha, :new_sha, to: :diff_file, prefix: :diff

      def initialize(diff_lines, repository: nil)
        @repository = repository

        if diff_lines.is_a?(Gitlab::Diff::File)
          @diff_file = diff_lines
          @diff_lines = @diff_file.diff_lines
        else
          @diff_lines = diff_lines
        end

        @raw_lines = @diff_lines.map(&:text)
      end

      def highlight
        @diff_lines.map.with_index do |diff_line, i|
          diff_line = diff_line.dup
          # ignore highlighting for "match" lines
          next diff_line if diff_line.meta?

          rich_line = highlight_line(diff_line) || ERB::Util.html_escape(diff_line.text)
          rich_line = Marker.new(diff_line.text, rich_line).mark(diff_line.highlight_diffs[0], diff_line.highlight_diffs[1])

          diff_line.rich_text = rich_line

          diff_line
        end
      end

      private

      def highlight_line(diff_line)
        return unless diff_file && diff_file.diff_refs

        blob_lines[diff_line.index]&.html_safe
      end

      def blob_lines
        @old_lines ||= highlighted_blob_lines(raw_lines.join("\n"))
      end

      def highlighted_blob_lines(blob)
        return [] unless blob

        Gitlab::Highlight.highlight(diff_file.new_path, blob).lines
      end
    end
  end
end
