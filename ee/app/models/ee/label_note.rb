# frozen_string_literal: true

module EE
  module LabelNote
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    private

    override :removed_prefix
    def removed_prefix
      scoped_labels_event? ?  'automatically removed' : super
    end

    override :added_suffix
    def added_suffix
      scoped_labels_event? ?  'scoped' : super
    end

    def scoped_labels_event?
      events.first.label&.scoped_label?
    end
  end
end
