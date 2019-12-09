# frozen_string_literal: true

module EE
  module Banzai
    module Filter
      module LabelReferenceFilter
        extend ::Gitlab::Utils::Override

        override :object_link_text
        def object_link_text(object, matches)
          presenter = label_link_text(object, matches)
          label_suffix = label_link_suffix(object, matches)

          content = if object.scoped_label?
                      ::EE::LabelsHelper.render_colored_scoped_label(presenter, label_suffix: label_suffix)
                    else
                      ::LabelsHelper.render_colored_label(presenter, label_suffix: label_suffix)
                    end

          content
        end

        override :wrap_link
        def wrap_link(link, label)
          content = super
          parent = project || group

          if label.scoped_label? && parent && parent.feature_available?(:scoped_labels)
            presenter = label.present(issuable_parent: parent)
            content = %(<span class="gl-label gl-label-scoped gl-label-sm" style="color: #{label.color}">#{link}</span>)
            content = ::EE::LabelsHelper.scoped_label_wrapper(content, presenter)
          end

          content
        end

        def tooltip_title(label)
          ::LabelsHelper.label_tooltip_title(label)
        end

        def object_link_title(object, matches)
          ::EE::LabelsHelper.label_tooltip_title(object)
        end
      end
    end
  end
end
