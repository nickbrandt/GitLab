# frozen_string_literal: true

module Gitlab
  module Diff
    module WordDiff
      class Marker < Gitlab::StringRangeMarker
        def initialize(line, rich_line = nil)
          super(line, rich_line || line)
        end

        def mark(removed, added)
          @rich_line = super(removed) do |text, left:, right:|
            %{<span class="#{html_class_names('removed')}">#{text}</span>}.html_safe
          end

          @position_mapping = nil

          super(added) do |text, left:, right:|
            %{<span class="#{html_class_names('added')}">#{text}</span>}.html_safe
          end
        end

        private

        def html_class_names(mode)
          ["idiff", mode].join(' ')
        end
      end
    end
  end
end
