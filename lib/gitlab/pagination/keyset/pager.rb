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
          relation = relation.limit(page.per_page) # rubocop: disable CodeReuse/ActiveRecord

          # Validate an assumption we're making (TODO: subject to be removed)
          check_order!(relation)

          apply_headers(relation.last)

          relation
        end

        private

        def apply_headers(last_record_in_page)
          lower_bounds = last_record_in_page&.slice(page.order_by.keys)
          next_page = page.next(lower_bounds, last_record_in_page.nil?)

          request.apply_headers(next_page)
        end

        def page
          @page ||= request.page
        end

        def order_by(rel)
          rel.order_values.map { |val| [val.expr.name, val.direction] }
        end

        def check_order!(rel)
          present_order = order_by(rel).last(2).to_h

          if to_sym_vals(page.order_by) != to_sym_vals(present_order)
            # The last two columns must match the page order_by
            raise "Page order_by doesnt match the relation\'s order: #{present_order} vs #{page.order_by}"
          end
        end

        def to_sym_vals(hash)
          hash.each_with_object({}) do |(k, v), h|
            h[k&.to_sym] = v&.to_sym
          end
        end
      end
    end
  end
end
