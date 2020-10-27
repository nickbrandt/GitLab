# frozen_string_literal: true

require "nokogiri"
require "zlib"
require "base64"

module Banzai
  module Filter
    # HTML that replaces all diagrams supported by Kroki with the corresponding img tags.
    #
    class KrokiFilter < HTML::Pipeline::Filter
      DIAGRAM_SELECTORS = ::Gitlab::Kroki::DIAGRAM_TYPES.map do |diagram_type|
        %(pre[lang="#{diagram_type}"] > code)
      end.join(', ')

      def call
        plantuml_enabled = settings.plantuml_enabled
        diagram_selectors = ::Gitlab::Kroki::DIAGRAM_TYPES.map do |diagram_type|
          # if PlantUML is enabled, PlantUML diagrams will be processed by the PlantUML filter.
          %(pre[lang="#{diagram_type}"] > code) if (plantuml_enabled && diagram_type != 'plantuml') || !plantuml_enabled
        end.compact.join(', ')
        return doc unless settings.kroki_enabled && doc.at(diagram_selectors)

        diagram_format = "svg"
        doc.css(DIAGRAM_SELECTORS).each do |node|
          diagram_type = node.parent['lang']
          img_tag = Nokogiri::HTML::DocumentFragment.parse(%(<img src="#{create_image_src(diagram_type, diagram_format, node.content)}"/>))
          node.parent.replace(img_tag)
        end

        doc
      end

      private

      # QUESTION: should should we use the asciidoctor-kroki gem to delegate this logic?
      def create_image_src(type, format, text)
        data = Base64.urlsafe_encode64(Zlib::Deflate.deflate(text, 9))
        "#{settings.kroki_url}/#{type}/#{format}/#{data}"
      end

      def settings
        Gitlab::CurrentSettings.current_application_settings
      end
    end
  end
end
