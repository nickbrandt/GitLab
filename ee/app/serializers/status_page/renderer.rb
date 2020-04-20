# frozen_string_literal: true

module StatusPage
  module Renderer
    def self.markdown(object, field)
      MarkupHelper.markdown_field(object, field)
    end
  end
end
