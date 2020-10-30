# frozen_string_literal: true

require "nokogiri"
require "zlib"
require "base64"

module Banzai
  module Filter
    # HTML that replaces all diagrams supported by Kroki with the corresponding img tags.
    #
    class KrokiFilter < HTML::Pipeline::Filter
      DIAGRAM_SELECTORS = ::Gitlab::Kroki::DIAGRAM_TYPES
                              .map { |diagram_type| %(pre[lang="#{diagram_type}"] > code) }
                              .join(', ')
      DIAGRAM_SELECTORS_WO_PLANTUML = ::Gitlab::Kroki::DIAGRAM_TYPES
                                          .select { |diagram_type| diagram_type != 'plantuml' }
                                          .map { |diagram_type| %(pre[lang="#{diagram_type}"] > code) }
                                          .join(', ')

      def call
        diagram_selectors = if settings.plantuml_enabled
                              # if PlantUML is enabled, PlantUML diagrams will be processed by the PlantUML filter.
                              DIAGRAM_SELECTORS_WO_PLANTUML
                            else
                              DIAGRAM_SELECTORS
                            end

        return doc unless settings.kroki_enabled && doc.at(diagram_selectors)

        diagram_format = "svg"
        doc.css(diagram_selectors).each do |node|
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
