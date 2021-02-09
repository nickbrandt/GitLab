# frozen_string_literal: true

module Gitlab
  module Diff
    module WordDiff
      class Parser
        include Enumerable

        class IncompleteString
          def initialize(line)
            @line = line
          end

          def type
            case line[0]
            when "+"
              "new"
            when "-"
              "old"
            else
              nil
            end
          end

          def to_s
            line[1..] || ''
          end

          def size
            to_s.size
          end

          private

          attr_reader :line
        end

        class DiffHunk
          def initialize(line)
            @line = line
          end

          def old_line
            line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
          end

          def new_line
            line.match(/\+[0-9]*/)[0].to_i.abs rescue 0
          end

          def to_s
            line
          end

          private

          attr_reader :line
        end

        class NewLineDelimeter
          def to_s
            ''
          end
        end

        class LineAnalyzer
          def initialize(line, type)
            @line = line
            @type = type
          end

          def present
            return if ignore?
            return DiffHunk.new(full_line) if diff_hunk?
            return NewLineDelimeter.new if new_line_delimeter?

            IncompleteString.new(full_line)
          end

          def diff_hunk?
            line =~ /^@@ -/
          end

          def ignore?
            # We're expecting a filename parameter only in a meta-part of the diff content
            # when type is defined then we're already in a content-part
            return true if filename? && type.nil?

            return true if full_line == ' '

            false
          end

          def new_line_delimeter?
            full_line == '~'
          end

          private

          attr_reader :line, :type

          def full_line
            @full_line ||= line.delete("\n")
          end

          def filename?
            line.start_with?( '--- /dev/null', '+++ /dev/null', '--- a', '+++ b',
                              '+++ a', # The line will start with `+++ a` in the reverse diff of an orphan commit
                              '--- /tmp/diffy', '+++ /tmp/diffy')
          end
        end

        def initialize
          @line_obj_index = 0
          @line_old = 1
          @line_new = 1
          @type = nil
          @unfinished_line = []
        end

        def parse(lines, diff_file: nil)
          return [] if lines.blank?

          # By returning an Enumerator we make it possible to search for a single line (with #find)
          # without having to instantiate all the others that come after it.
          Enumerator.new do |yielder|
            lines.each do |line|
              element = LineAnalyzer.new(line, type).present

              case element
              when DiffHunk
                @line_old = element.old_line
                @line_new = element.new_line

                next if @line_old <= 1 && @line_new <= 1 # top of file

                yielder << Gitlab::Diff::Line.new(element.to_s, 'match', @line_obj_index, @line_old, @line_new, parent_file: diff_file)
                @line_obj_index += 1
                next
              when NewLineDelimeter
                if @unfinished_line.empty?
                  yielder << Gitlab::Diff::Line.new(element.to_s, 'word-diff', @line_obj_index, @line_old, @line_new, parent_file: diff_file, highlight_diffs: [[], []])
                else
                  content = ''
                  highlight_diffs = [[], []]

                  @unfinished_line.each do |element|
                    highlight_diffs[0] << (content.size...content.size + element.size) if element.type == 'old'
                    highlight_diffs[1] << (content.size...content.size + element.size) if element.type == 'new'
                    content += element.to_s
                  end

                  @unfinished_line = []

                  yielder << Gitlab::Diff::Line.new(content, 'word-diff', @line_obj_index, @line_old, @line_new, parent_file: diff_file, highlight_diffs: highlight_diffs)
                end

                @line_obj_index += 1
                @line_new += 1
                @line_old += 1

              when IncompleteString
                @type = element.type
                @unfinished_line << element
              end
            end
          end
        end

        private

        attr_accessor :line_obj_index, :line_old, :line_new, :type
      end
    end
  end
end
