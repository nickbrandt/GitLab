# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class EventCounters < RuboCop::Cop::Cop
        MSG = 'Use the `count` or `distinct_count`'

        def_node_matcher :events_table, <<~PATTERN
          $(send (const {nil cbase} :Event ) ...)
        PATTERN

        def on_send(node)
          return unless usage_data_files?(node)

          matched_node = events_table(node)

          return if matched_node.nil?

          method_name = matched_node.parent.children[1]

          add_offense(node, location: :expression) unless [:count, :distinct_count].include?(method_name)
        end

        private

        def usage_data_files?(node)
          path = node.location.expression.source_buffer.name
          path.include?('usage_data.rb')
        end
      end
    end
  end
end
