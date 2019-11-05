# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class Pager
        attr_reader :request

        def initialize(request)
          @request = request
        end

        def paginate(relation)
          paged_relation = relation.limit(page.per_page).reorder(page.column => :asc) # rubocop: disable CodeReuse/ActiveRecord

          if val = page.last_value
            # TODO: check page.column is valid
            paged_relation = paged_relation.where("#{page.column} > ?", val) # rubocop: disable CodeReuse/ActiveRecord
          end

          PagedRelation.new(paged_relation, page)
        end

        private

        def page
          @page ||= request.page
        end
      end
    end
  end
end
