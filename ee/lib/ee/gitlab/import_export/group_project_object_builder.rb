# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module GroupProjectObjectBuilder
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        private

        override :where_clause_for_klass
        def where_clause_for_klass
          return attrs_to_arel(attributes.slice('filename')).and(table[:issue_id].eq(nil)) if design?

          super
        end

        def design?
          klass == DesignManagement::Design
        end
      end
    end
  end
end
