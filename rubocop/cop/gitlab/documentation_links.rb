# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      class DocumentationLinks < RuboCop::Cop::Cop
        include CodeReuseHelpers

        MARKDOWN_HEADER = %r{\A\#{1,6}\s+(?<header>.+?)\Z}.freeze

        def_node_matcher :help_page_path, <<~PATTERN
        (send nil? :help_page_path $...)
        PATTERN

        def on_send(node)
          match = extract_link_and_anchor(node)

          return if match.empty?

          path_to_file = detect_path_to_file(match[:link])

          unless File.file?(path_to_file)
            add_offense(node, location: :selector, message: 'Documentation link is missing')
            return false
          end

          unless correct_anchor?(path_to_file, match[:anchor])
            add_offense(node, location: :selector, message: 'Invalid anchor')
            return false
          end
        end

        private

        def extract_link_and_anchor(node)
          link_match, attributes_match = help_page_path(node)

          { link: fetch_link(link_match), anchor: fetch_anchor(attributes_match) }.compact
        end

        def detect_path_to_file(link)
          path = File.join(rails_root, 'doc', link)
          path += '.md' unless path.end_with?('.md')
          path
        end

        def fetch_link(link_match)
          return unless link_match && link_match.str_type?

          link_match.value
        end

        def fetch_anchor(attributes_match)
          return unless attributes_match

          attributes_match.each_pair do |pkey, pvalue|
            return pvalue.value if pkey.value == :anchor && pvalue.str_type?
          end

          nil
        end

        def correct_anchor?(path_to_file, anchor)
          return true unless anchor

          File.readlines(path_to_file).any? do |line|
            result = line.match(MARKDOWN_HEADER)

            slugify(result[:header]) == anchor if result
          end
        end

        def slugify(string)
          string
            .gsub(/[ -]/, '_')
            .gsub(/\W/, '')
            .dasherize
            .downcase
        end
      end
    end
  end
end
