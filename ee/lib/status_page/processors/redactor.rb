# frozen_string_literal: true

module StatusPage
  module Processors
    module Redactor
      def self.process(html, **kwargs)
        Banzai.post_process(html, project: nil)
      end
    end
  end
end
