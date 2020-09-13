# frozen_string_literal: true

module Gitlab
  module Kroki
    # QUESTION: should we use the asciidoctor-kroki gem?
    DIAGRAM_TYPES = %w(plantuml ditaa graphviz blockdiag seqdiag actdiag nwdiag packetdiag rackdiag c4plantuml erd mermaid nomnoml svgbob umlet vega vegalite wavedrom).freeze
  end
end
