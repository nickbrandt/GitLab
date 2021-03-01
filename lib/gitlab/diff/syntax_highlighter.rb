# frozen_string_literal: true

module Gitlab
  module Diff
    class SyntaxHighlighter
      def initialize(diff_file)
        @diff_file = diff_file
      end

      def highlight(diff_line)
        rich_line = fetch_rich_line(diff_line)

        # Only update text if line is found. This will prevent
        # issues with submodules given the line only exists in diff content.
        return unless rich_line

        line_prefix = diff_line.text =~ /\A(.)/ ? Regexp.last_match(1) : ' '
        "#{line_prefix}#{rich_line}".html_safe
      end

      private

      attr_reader :diff_file

      def fetch_rich_line(diff_line)
        if diff_line.unchanged? || diff_line.added?
          new_lines[diff_line.new_pos - 1]&.html_safe
        elsif diff_line.removed?
          old_lines[diff_line.old_pos - 1]&.html_safe
        end
      end

      def old_lines
        @old_lines ||= highlighted_blob_lines(diff_file.old_blob)
      end

      def new_lines
        @new_lines ||= highlighted_blob_lines(diff_file.new_blob)
      end

      def highlighted_blob_lines(blob)
        return [] unless blob

        blob.load_all_data!
        blob.present.highlight.lines
      end
    end
  end
end
