# frozen_string_literal: true

module Gitlab
  module Diff
    module WordDiff
      class Parser
        include Enumerable

        # rubocop: disable Metrics/CyclomaticComplexity
        # rubocop: disable Metrics/PerceivedComplexity
        def parse(lines, diff_file: nil)
          return [] if lines.blank?

          @lines = lines
          line_obj_index = 0
          line_old = 1
          line_new = 1
          type = nil

          # By returning an Enumerator we make it possible to search for a single line (with #find)
          # without having to instantiate all the others that come after it.
          Enumerator.new do |yielder|
            unfinished_line = ''
            highlight_diffs = [[], []]

            @lines.each do |line|
              # We're expecting a filename parameter only in a meta-part of the diff content
              # when type is defined then we're already in a content-part
              next if filename?(line) && type.nil?

              full_line = line.delete("\n")

              if line =~ /^@@ -/
                line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
                line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0

                next if line_old <= 1 && line_new <= 1 # top of file

                yielder << Gitlab::Diff::Line.new(full_line, 'match', line_obj_index, line_old, line_new, parent_file: diff_file)
                line_obj_index += 1
                next
              end

              if full_line == ' '
                next
              end

              # Newline delimeter
              if full_line == '~'
                if unfinished_line
                  yielder << Gitlab::Diff::Line.new(unfinished_line, 'word-diff', line_obj_index, line_old, line_new, parent_file: diff_file, highlight_diffs: highlight_diffs)
                  line_obj_index += 1
                  unfinished_line = ''
                  highlight_diffs = [[], []]
                else
                  yielder << Gitlab::Diff::Line.new(' ', type, line_obj_index, line_old, line_new, parent_file: diff_file)
                end

                line_new += 1
                line_old += 1
              else
                type = identification_type(line)
                short_line = full_line[1..] || ''

                if type == 'old'
                  highlight_diffs[0] << (unfinished_line.size...unfinished_line.size + short_line.size)
                end

                if type == 'new'
                  highlight_diffs[1] << (unfinished_line.size...unfinished_line.size + short_line.size)
                end

                unfinished_line += short_line
              end
            end
          end
        end
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/PerceivedComplexity

        def empty?
          @lines.empty?
        end

        private

        def filename?(line)
          line.start_with?( '--- /dev/null', '+++ /dev/null', '--- a', '+++ b',
                            '+++ a', # The line will start with `+++ a` in the reverse diff of an orphan commit
                            '--- /tmp/diffy', '+++ /tmp/diffy')
        end

        def identification_type(line)
          case line[0]
          when "+"
            "new"
          when "-"
            "old"
          else
            nil
          end
        end
      end
    end
  end
end
