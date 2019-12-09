# frozen_string_literal: true

module EE
  module LabelsHelper
    extend ActiveSupport::Concern

    prepended do
      singleton_class.prepend self
    end

    def render_label(label, tooltip: true, link: nil, dataset: nil, small: false)
      if label.scoped_label?
        render_scoped_label(
          label,
          link: link,
          css: label_css_classes(tooltip),
          dataset: label_dataset(label, dataset, tooltip),
          small: small
        )
      else
        super
      end
    end

    def render_scoped_label(label, link: nil, css: nil, dataset: nil, small: false)
      # if scoped label is used then EE wraps label tag with scoped label
      # doc link
      size_class = small ? "gl-label-sm" : ""
      html = render_colored_scoped_label(label)
      html = link_to(html, link, class: css, data: dataset) if link

      html = %(<span class="gl-label gl-label-scoped #{size_class}" style="color: #{label.color}">#{html}</span>)
      wrapped_html = scoped_label_wrapper(html, label)

      wrapped_html.html_safe
    end

    def render_colored_scoped_label(label, label_suffix: '')
      text_color_class = ::LabelsHelper.text_color_class_for_bg(label.color)
      scope_name, label_name = label.name.split(Label::SCOPED_LABEL_SEPARATOR)

      # Intentionally not using content_tag here so that this method can be called
      # by LabelReferenceFilter
      # Tooltip is omitted as it's attached to the link containing label title on scoped labels
      ::LabelsHelper.render_partial_label(
        label, label_suffix: label_suffix,
        label_name: scope_name,
        css_class: text_color_class,
        bg_color: label.color
      ) + ::LabelsHelper.render_partial_label(
        label, label_suffix: label_suffix,
        label_name: label_name,
        css_class: 'gl-label-scoped-text'
      )
    end

    def scoped_label_wrapper(link, label)
      %(<span class="d-inline-block position-relative scoped-label-wrapper">#{link}#{scoped_labels_doc_link(label)}</span>).html_safe
    end

    def scoped_labels_doc_link(label)
      content = %(<i class="fa fa-question-circle"></i>)
      help_url = ::Gitlab::Routing.url_helpers.help_page_url('user/project/labels.md', anchor: 'scoped-labels')

      %(<a href="#{help_url}" class="label scoped-label gl-link gl-label-icon" target="_blank" rel="noopener">#{content}</a>)
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

    def scoped_labels_doc_link(label)
      text_color = text_color_for_bg(label.color)
      content = %(<i class="fa fa-question-circle" style="background-color: #{label.color}; color: #{text_color}"></i>)
      help_url = ::Gitlab::Routing.url_helpers.help_page_url('user/project/labels.md', anchor: 'scoped-labels')

      %(<a href="#{help_url}" class="label scoped-label" target="_blank" rel="noopener">#{content}</a>)
    end

    module_function :render_colored_scoped_label, :scoped_label_wrapper, :scoped_labels_doc_link, :label_tooltip_title
  end
end
