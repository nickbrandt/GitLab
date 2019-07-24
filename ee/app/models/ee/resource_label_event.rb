# frozen_string_literal: true

module EE
  module ResourceLabelEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      belongs_to :epic
    end

    class_methods do
      def issuable_attrs
        %i(epic).freeze + super
      end
    end

    override :discussion_id_key
    def discussion_id_key
      (super + [label&.scoped_label?]).compact # label can be nil as we don't remove resource events when deleting labels
    end

    override :issuable
    def issuable
      epic || super
    end

    override :banzai_render_context
    def banzai_render_context(field)
      epic ? super.merge(label_url_method: :group_epics_url) : super
    end
  end
end
