# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `allow_any_instance_of` or `expect_any_instance_of`
      # usage in specs.
      #
      # @example
      #
      #   # bad
      #   allow_any_instance_of(User).to receive(:invalidate_issue_cache_counts)
      #
      #   # bad
      #   expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts)
      #
      #   # good
      #   allow_next_instance_of(User) do |instance|
      #     allow(instance).to receive(:invalidate_issue_cache_counts)
      #   end
      #
      #   # good
      #   expect_next_instance_of(User) do |instance|
      #     expect(instance).to receive(:invalidate_issue_cache_counts)
      #   end
      #
      class AnyInstanceOf < RuboCop::Cop::Cop
        MESSAGE_EXPECT = 'Do not use `expect_any_instance_of` method, use `expect_next_instance_of` instead.'
        MESSAGE_ALLOW = 'Do not use `allow_any_instance_of` method, use `allow_next_instance_of` instead.'

        def_node_search :expect_any_instance_of?, <<~PATTERN
          (send
            (send nil? :expect_any_instance_of ...) _ ...
          )
        PATTERN
        def_node_search :allow_any_instance_of?, <<~PATTERN
          (send
            (send nil? :allow_any_instance_of ...) _ ...
          )
        PATTERN

        def on_send(node)
          if expect_any_instance_of?(node)
            add_offense(node, location: :expression, message: MESSAGE_EXPECT)
          elsif allow_any_instance_of?(node)
            add_offense(node, location: :expression, message: MESSAGE_ALLOW)
          end
        end

        def autocorrect(node)
          if expect_any_instance_of?(node)
            replacement = replacement_expect_any_instance_of(node)
          elsif allow_any_instance_of?(node)
            replacement = replacement_allow_any_instance_of(node)
          end

          lambda do |corrector|
            corrector.replace(node.loc.expression, replacement)
          end
        end

        private

        def replacement_expect_any_instance_of(node)
          replacement = node.receiver.source.sub('expect_any_instance_of', 'expect_next_instance_of')
          replacement << " do |instance|\n"
          replacement << "  expect(instance).#{node.method_name} #{node.children.last.source}\n"
          replacement << 'end'
        end

        def replacement_allow_any_instance_of(node)
          replacement = node.receiver.source.sub('allow_any_instance_of', 'allow_next_instance_of')
          replacement << " do |instance|\n"
          replacement << "  allow(instance).#{node.method_name} #{node.children.last.source}\n"
          replacement << 'end'
        end
      end
    end
  end
end
