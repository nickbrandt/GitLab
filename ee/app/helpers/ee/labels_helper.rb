# frozen_string_literal: true

module EE
  module LabelsHelper
    def render_label(label, tooltip: true, link: nil, css: nil, dataset: nil)
      content = super
      content = scoped_label_wrapper(content, label) if label.scoped_label?

      content
    end

    def scoped_label_wrapper(link, label)
      %(<span class="d-inline-block position-relative scoped-label-wrapper">#{link}#{scoped_labels_doc_link(label)}</span>).html_safe
    end

    def scoped_labels_doc_link(label)
      text_color = ::LabelsHelper.text_color_for_bg(label.color)
      content = %(<i class="fa fa-question-circle" style="background-color: #{label.color}; color: #{text_color}"></i>)
      help_url = ::Gitlab::Routing.url_helpers.help_page_url('user/project/labels.md', anchor: 'scoped-labels')

      %(<a href="#{help_url}" class="label scoped-label" target="_blank" rel="noopener">#{content}</a>)
    end

    def label_tooltip_title(label)
      # can't use `super` because this is called also as a module method from
      # banzai
      tooltip = ::LabelsHelper.label_tooltip_title(label)
      tooltip = %(<span class='font-weight-bold scoped-label-tooltip-title'>Scoped label</span><br />#{tooltip}) if label.scoped_label?

      tooltip
    end

    def label_dropdown_data(edit_context, opts = {})
      scoped_labels_fields = {
        scoped_labels: edit_context&.feature_available?(:scoped_labels)&.to_s,
        scoped_labels_documentation_link: help_page_path('user/project/labels.md', anchor: 'scoped-labels')
      }

      return super.merge(scoped_labels_fields) unless edit_context.is_a?(Group)

      {
        toggle: "dropdown",
        field_name: opts[:field_name] || "label_name[]",
        show_no: "true",
        show_any: "true",
        group_id: edit_context&.try(:id)
      }.merge(scoped_labels_fields, opts)
    end

    def sidebar_label_dropdown_data(issuable_type, issuable_sidebar)
      super.merge({
        scoped_labels: issuable_sidebar[:scoped_labels_available].to_s
      })
    end

    def issuable_types
      return super unless @group&.feature_available?(:epics)

      super + ['epics']
    end

    module_function :scoped_label_wrapper, :scoped_labels_doc_link, :label_tooltip_title
  end
end
