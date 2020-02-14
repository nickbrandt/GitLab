# frozen_string_literal: true

module EE
  module Banzai
    module Filter
      module LabelReferenceFilter
        extend ::Gitlab::Utils::Override

        override :wrap_link
        def wrap_link(link, label)
          content = super
          parent = project || group

          if label.scoped_label? && parent && parent.feature_available?(:scoped_labels)
            presenter = label.present(issuable_parent: parent)
            content = ::LabelsHelper.scoped_label_wrapper(content, presenter)
          end

          content
        end

        def tooltip_title(label)
          ::LabelsHelper.label_tooltip_title(label)
        end
      end
    end
  end
end
