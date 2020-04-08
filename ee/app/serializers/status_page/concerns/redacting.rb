# frozen_string_literal: true

module StatusPage
  module Redacting
    extend ActiveSupport::Concern

    class_methods do
      def redact(field, html_field = :"#{field}_html")
        define_method(field) do
          Banzai.post_process(object.public_send(html_field), { project: nil }) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
