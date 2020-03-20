# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      class AvoidReadFile < RuboCop::Cop::Cop
        MESSAGE = 'dont use this'

        def_node_matcher :full_file_read_via_class?, <<~PATTERN
          (send
            (const nil? {:IO :File}) {:read :readlines} #external_path?)
        PATTERN

        def_node_matcher :full_file_read_via_instance?, <<~PATTERN
          (send
            (send nil? #instance_not_allowed?) {:read :readlines})
        PATTERN

        def on_send(node)
          # pp node
          full_file_read_via_class?(node) { add_offense(node, location: :selector, message: MESSAGE) }
          full_file_read_via_instance?(node) { add_offense(node, location: :selector, message: MESSAGE) }
        end

        private

        def instance_not_allowed?(symbol)
          ![:stdout, :stderr].include?(symbol)
        end

        # Tests whether the given path argument points to a file within the application
        # root, in which case we consider it safe to load.
        def external_path?(path)
          is_rails_root =
            path.type == :str && path.value&.include?("Rails.root") ||
              argument_nodes(path).any? { |node| node&.const_name == 'Rails' }
          !is_rails_root
        end

        def argument_nodes(path)
          path_arg = path.descendants.first
          [path_arg&.receiver] + (path_arg&.receiver&.descendants || [])
        end
      end
    end
  end
end
