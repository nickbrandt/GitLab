# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # This cop checks for unsafe use of class methods that mutate the receiver
      # where changes might survive across test boundaries. Only applied in specs.
      #
      # @example
      #
      #   # bad
      #   ExistingModelClass.set_callback :name, { ... }
      #
      #   # good
      #   class OnlyExistsInSpec
      #     set_callback :name, { ... }
      #   end
      #
      class ClassMutation < RuboCop::Cop::Cop
        MESSAGE = 'This method call results in permanent changes to the receiver class and may have side-effects on other tests.'

        BLACKLISTED_METHODS = Set[
          :set_callback,
          :skip_callback,
          :validates,
          # Methods below taken from ActiveRecord::Callbacks::CALLBACKS
          :after_initialize,
          :after_find,
          :after_touch,
          :before_validation,
          :after_validation,
          :before_save,
          :around_save,
          :after_save,
          :before_create,
          :around_create,
          :after_create,
          :before_update,
          :around_update,
          :after_update,
          :before_destroy,
          :around_destroy,
          :after_destroy,
          :after_commit,
          :after_rollback
        ].freeze

        def on_send(node)
          if node.send_type?
            if BLACKLISTED_METHODS.include?(node.method_name)
              add_offense(node, location: :expression, message: MESSAGE)
            end
          end
        end
      end
    end
  end
end
