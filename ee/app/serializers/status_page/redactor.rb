# frozen_string_literal: true

module StatusPage
  module Redactor
    def self.redact(html)
      Banzai.post_process(html, project: nil)
    end
  end
end
