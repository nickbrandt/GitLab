# frozen_string_literal: true

module EE
  module AppearancesHelper
    extend ::Gitlab::Utils::Override

    def header_message
      return unless current_appearance&.show_header?

      class_names = []
      class_names << 'with-performance-bar' if performance_bar_enabled?

      render_message(:header_message, class_names)
    end

    def footer_message
      return unless current_appearance&.show_footer?

      render_message(:footer_message)
    end

    override :default_brand_title
    def default_brand_title
      'GitLab Enterprise Edition'
    end

    private

    def render_message(field_sym, class_names = [])
      class_names << field_sym.to_s.dasherize

      content_tag :div, class: class_names, style: message_style do
        markdown_field(current_appearance, field_sym)
      end
    end

    def message_style
      style = []
      style << "background-color: #{current_appearance.message_background_color};"
      style << "color: #{current_appearance.message_font_color}"
      style.join
    end
  end
end
