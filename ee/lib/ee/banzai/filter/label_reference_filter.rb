# frozen_string_literal: true

module EE
  module Banzai
    module Filter
      module LabelReferenceFilter
        extend ::Gitlab::Utils::Override

        override :wrap_link
        def wrap_link(link, label)
          content = super
          content = ::EE::LabelsHelper.scoped_label_wrapper(content, label) if label.scoped_label?

          content
        end

        def tooltip_title(label)
          ::EE::LabelsHelper.label_tooltip_title(label)
        end
      end
    end
  end
end
