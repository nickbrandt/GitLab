# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      class AvoidIoRead < RuboCop::Cop::Cop
        MESSAGE = 'Avoid `IO.read[lines]`, since contents are read into memory in full. ' \
          'Prefer by-line processing via `readline` or `gets` or specify read length in bytes.'

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
          !(rails_root_string?(path) || rails_root_call?(path))
        end

        def rails_root_string?(path)
          path.type == :str && path.value&.include?("Rails.root")
        end

        def rails_root_call?(path)
          all_calls = path.descendants
          first_call = all_calls.first
          all_receivers = [first_call&.receiver] + (first_call&.receiver&.descendants || [])
          all_receivers.any? { |node| node&.const_name == 'Rails' } &&
            all_calls.any? { |node| node&.method_name == :root }
        end
      end
    end
  end
end
