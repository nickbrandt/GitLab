# frozen_string_literal: true

module Gitlab
  module Insights
    module Reducers
      class CountPerLabelReducer < BaseReducer
        InvalidLabelsError = Class.new(BaseReducerError)

        def initialize(issuables, labels:)
          super(issuables)
          @labels = Array(labels)

          validate!
        end

        # Returns a hash { label => issuables_count }, e.g.
        #   {
        #     #<InsightLabel @title='Manage', @color='#990000'> => 1,
        #     #<InsightLabel @title='Plan', @color='#009900'> => 1,
        #     #<InsightLabel @title='undefined', @color='#000099'> => 2
        #   }
        def reduce
          count_per_label
        end

        private

        attr_reader :labels

        def validate!
          unless labels.any?
            raise InvalidLabelsError, "Invalid value for `labels`: `#{labels}`. It must be a non-empty array!"
          end
        end

        def count_per_label
          issuables.each_with_object(initial_labels_count_hash) do |issuable, hash|
            first_matching_label = first_matching_insight_label(issuable)

            insight_label, _ = hash.detect { |k, _| k == first_matching_label }
            insight_label.color ||= first_matching_label.color

            hash[insight_label] += 1
          end
        end

        def first_matching_insight_label(issuable)
          issuable_labels_by_title = insights_labels_by_title(issuable)
          first_matching_label_title = (labels & issuable_labels_by_title.keys).first

          issuable_labels_by_title.fetch(first_matching_label_title, uncategorized_label)
        end

        # Returns a { label_title => InsightLabel } hash.
        def insights_labels_by_title(issuable)
          issuable.labels.each_with_object({}) do |label, memo|
            memo[label.title] = InsightLabel[label.title, label.color]
          end
        end

        def initial_labels_count_hash
          # Eager-load all labels' color here.
          (labels + [uncategorized_label.title]).each_with_object({}) do |label, hash|
            hash[InsightLabel[label]] = 0
          end
        end

        def uncategorized_label
          @uncategorized_label ||= InsightLabel.new(Gitlab::Insights::UNCATEGORIZED, Gitlab::Insights::UNCATEGORIZED_COLOR)
        end
      end
    end
  end
end
