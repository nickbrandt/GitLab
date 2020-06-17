# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Features
        extend ActiveSupport::Concern

        prepended do
          def self.secrets_syntax_enabled?
            ::Feature.enabled?(:ci_secrets_syntax)
          end
        end
      end
    end
  end
end
