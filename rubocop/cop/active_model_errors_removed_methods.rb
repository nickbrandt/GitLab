# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that avoid ActiveModel#errors methods which will be removed in Rails 7.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/225874
    class ActiveModelErrorsRemovedMethods < RuboCop::Cop::Cop
      MSG = 'Avoid calling errors hash methods. For more details check https://gitlab.com/gitlab-org/gitlab/-/issues/225874'
      METHODS = ":keys :values :slice :slice! :to_h :to_xml"

      def_node_matcher :active_model_errors_removed_hash_methods?, <<~PATTERN
        (send
          (send {send ivar lvar} :errors)
          {#{METHODS}})
      PATTERN

      def on_send(node)
        add_offense(node, location: :expression) if active_model_errors_removed_hash_methods?(node)
      end
    end
  end
end
