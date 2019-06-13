# frozen_string_literal: true

module EE
  module AutoMergeService
    extend ActiveSupport::Concern

    STRATEGY_MERGE_TRAIN = 'merge_train'.freeze
    EE_STRATEGIES = [STRATEGY_MERGE_TRAIN].freeze

    class_methods do
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :all_strategies
      def all_strategies
        strong_memoize(:all_strategies) do
          super + EE_STRATEGIES
        end
      end
    end
  end
end
