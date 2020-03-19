# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      class AvoidReadFile < RuboCop::Cop::Cop
        MESSAGE = 'dont use this'

        def_node_matcher :full_file_read_via_class?, <<~PATTERN
          (send
            (const nil? {:IO :File}) {:read :readlines} _)
        PATTERN

        def_node_matcher :full_file_read_via_instance?, <<~PATTERN
          (send
            (send nil? #instance_not_allowed?) {:read :readlines})
        PATTERN

        def on_send(node)
          full_file_read_via_class?(node) { add_offense(node, location: :selector, message: MESSAGE) }
          full_file_read_via_instance?(node) { add_offense(node, location: :selector, message: MESSAGE) }
        end

        def instance_not_allowed?(symbol)
          ![:stdout, :stderr].include?(symbol)
        end
      end
    end
  end
end
