# frozen_string_literal: true

module EE
  module Identity
    module UniquenessScopes
      extend ActiveSupport::Concern

      class_methods do
        def scopes
          [*super, :saml_provider_id]
        end
      end
    end
  end
end
