# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class PagedRelation
        attr_reader :relation, :page

        def initialize(relation, page)
          @relation = relation
          @page = page
        end

        # return Page information for next page
        def next_page
          last_record_in_page = relation.last
          last_value = last_record_in_page&.read_attribute(page.column)

          Page.new(last_value, column: page.column, per_page: page.per_page)
        end
      end
    end
  end
end
