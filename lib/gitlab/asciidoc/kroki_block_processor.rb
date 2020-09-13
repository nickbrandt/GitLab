# frozen_string_literal: true

require 'asciidoctor'

module Gitlab
  module Asciidoc
    # Kroki BlockProcessor
    #
    class KrokiBlockProcessor < ::Asciidoctor::Extensions::BlockProcessor
      use_dsl

      on_context :literal, :listing
      parse_content_as :simple

      def process(parent, reader, attrs)
        diagram_type = @name
        diagram_text = reader.string
        create_kroki_source_block(parent, diagram_type, diagram_text, attrs)
      end

      private

      def create_kroki_source_block(parent, diagram_type, diagram_text, attrs)
        # If "subs" attribute is specified, substitute accordingly.
        # Be careful not to specify "specialcharacters" or your diagram code won't be valid anymore!
        subs = attrs['subs']
        diagram_text = parent.apply_subs(diagram_text, parent.resolve_subs(subs)) if subs
        html = %(<div><pre data-kroki-style="display" lang="#{diagram_type}"><code>#{CGI.escape_html(diagram_text)}</code></pre></div>)
        ::Asciidoctor::Block.new(parent, :pass, {
          content_model: :raw,
          source: html,
          subs: :default
        }.merge(attrs))
      end
    end
  end
end
