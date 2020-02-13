# frozen_string_literal: true

module EE
  module LabelsHelper
    extend ActiveSupport::Concern

    prepended do
      singleton_class.prepend self
    end

    def render_label(label, tooltip: true, link: nil, dataset: nil, small: false)
      return super unless label.scoped_label?

      scoped_label_doc_wrapper(
        super(
          label,
          tooltip: tooltip,
          link: link,
          dataset: dataset,
          small: small,
          wrapper_class: 'gl-label-scoped',
          wrapper_style: "color: #{label.color}"
        ),
        label
      )
    end

    def render_colored_label(label, label_suffix: '')
      return super unless label.scoped_label?

      text_color_class = text_color_class_for_bg(label.color)
      scope_name, label_name = label.name.split(Label::SCOPED_LABEL_SEPARATOR)

      # Tooltip is omitted as it's attached to the link containing label title on scoped labels
      render_partial_label(
        label, label_suffix: label_suffix,
        label_name: scope_name,
        css_class: text_color_class,
        bg_color: label.color
      ) + render_partial_label(
        label, label_suffix: label_suffix,
        label_name: label_name,
        css_class: 'gl-label-scoped-text'
      )
    end

    def scoped_label_doc_wrapper(link, label)
      %(<span class="d-inline-block position-relative scoped-label-wrapper">#{link}#{scoped_labels_doc_link(label)}</span>).html_safe
    end

    def label_tooltip_title(label)
      tooltip = super
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

    private

    def scoped_labels_doc_link(label)
      content = %(<i class="fa fa-question-circle"></i>)
      help_url = ::Gitlab::Routing.url_helpers.help_page_url('user/project/labels.md', anchor: 'scoped-labels')

      %(<a href="#{help_url}" class="label scoped-label gl-link gl-label-icon" target="_blank" rel="noopener">#{content}</a>)
    end
  end
end
