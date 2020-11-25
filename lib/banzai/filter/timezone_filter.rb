# frozen_string_literal: true

module Banzai
  module Filter
    class TimezoneFilter < ReferenceFilter
      self.reference_type = :timezone

      def self.references_in(text)
        text.gsub(/{(?<timezone>.+)}/) do |match|
          yield match, $~[:timezone]
        end
      end

      def call
        ref_pattern = %r{{.+}}

        nodes.each_with_index do |node, index|
          if text_node?(node)
            replace_text_when_pattern_matches(node, index, ref_pattern) do |content|
              timezone_link_filter(content)
            end
          end
        end

        doc
      end

      def timezone_link_filter(text, link_content: nil)
        self.class.references_in(text) do |match, timezone|
          # parsed_timezone = DateTime.parse('2012-08-13 13:21 UTC+2')
          parsed_timezone = DateTime.parse(timezone).strftime('%Y-%m-%d %H:%M %z')
          span_to_timezone(parsed_timezone)
        rescue Date::Error
          match
        end
      end

      private

      def link_class
        [reference_class(:timezone, tooltip: false), 'js-timezone-link'].join(' ')
      end

      def span_to_timezone(timezone)
        data = data_attribute(timezone: timezone)

        span_tag(data, timezone)
      end

      def span_tag(data, timezone)
        %(<span #{data} class="#{link_class}">#{timezone}</span>)
      end
    end
  end
end
