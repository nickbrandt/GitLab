# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class RequestContext
        attr_reader :request

        DEFAULT_SORT_DIRECTION = :asc
        TIE_BREAKER = { id: :desc }.freeze

        def initialize(request)
          @request = request
        end

        # extracts Paging information from request parameters
        def page
          Page.new(order_by: order_by, per_page: params[:per_page])
        end

        def apply_headers(next_page)
          request.header('Links', pagination_links(next_page))
        end

        private

        def order_by
          return TIE_BREAKER.dup unless params[:order_by]

          order_by = { params[:order_by]&.to_sym => params[:sort]&.to_sym || DEFAULT_SORT_DIRECTION }

          # Order by an additional unique key, we use the primary key here
          order_by = order_by.merge(TIE_BREAKER) unless order_by[:id]

          order_by
        end

        def lower_bounds_params(page)
          page.lower_bounds.each_with_object({}) do |(column, value), params|
            filter = filter_with_comparator(page, column)
            params[filter] = value
          end
        end

        def filter_with_comparator(page, column)
          direction = page.order_by[column]

          if direction&.to_sym == :desc
            "#{column}_before"
          else
            "#{column}_after"
          end
        end

        def params
          @params ||= request.params
        end

        def pagination_links(next_page)
          return if next_page.end_reached?

          %(<#{page_href(next_page)}>; rel="next")
        end

        def base_request_uri
          @base_request_uri ||= URI.parse(request.request.url).tap do |uri|
            uri.host = Gitlab.config.gitlab.host
            uri.port = Gitlab.config.gitlab.port
          end
        end

        def query_params_for(page)
          request.params.merge(lower_bounds_params(page))
        end

        def page_href(page)
          base_request_uri.tap do |uri|
            uri.query = query_params_for(page).to_query
          end.to_s
        end
      end
    end
  end
end
