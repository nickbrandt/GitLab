# frozen_string_literal: true

module EE
  module IssuableBaseService
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :label_ids_ordered_by_selection

    private

    override :filter_params
    def filter_params(issuable)
      # This security check is repeated here to avoid multiple backports,
      # this should be refactored to be reused from the base class.
      ability_name = :"admin_#{issuable.to_ability_name}"

      unless issuable.supports_weight? && can?(current_user, ability_name, issuable)
        params.delete(:weight)
      end

      super
    end

    override :filter_labels
    def filter_labels
      @label_ids_ordered_by_selection = params[:add_label_ids].to_a + params[:label_ids].to_a # rubocop:disable Gitlab/ModuleWithInstanceVariables

      super
    end

    def update_task_event?
      strong_memoize(:update_task_event) do
        params.key?(:update_task)
      end
    end

    override :process_label_ids
    def process_label_ids(attributes, existing_label_ids: nil, extra_label_ids: [])
      ids = super
      added_label_ids = ids - existing_label_ids.to_a

      filter_mutually_exclusive_labels(ids, added_label_ids)
    end

    def filter_mutually_exclusive_labels(ids, added_label_ids)
      return ids if added_label_ids.empty? || !parent.feature_available?(:scoped_labels)

      label_sets = ScopedLabelSet.from_label_ids(ids)

      label_sets.map do |set|
        if set.valid? || !set.contains_any?(added_label_ids)
          set.label_ids
        else
          set.last_id_by_order(label_ids_ordered_by_selection)
        end
      end.flatten
    end
  end
end
