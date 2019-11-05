# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class RequestContext
        attr_reader :request

        REQUEST_PARAM = :id_after

        def initialize(request)
          @request = request
        end

        # extracts Paging information from request parameters
        def page
          last_value = request.params[REQUEST_PARAM]

          Page.new(last_value, per_page: request.params[:per_page], is_first_page: !last_value.nil?)
        end

        def apply_headers(paged_relation)
          next_page = paged_relation.next_page
          links = pagination_links(next_page)

          request.header('Links', links.join(', '))
        end

        private

        def pagination_links(next_page)
          [].tap do |links|
            links << %(<#{page_href}>; rel="first")
            links << %(<#{page_href(next_page)}>; rel="next") unless next_page.empty?
          end
        end

        def base_request_uri
          @base_request_uri ||= URI.parse(request.request.url).tap do |uri|
            uri.host = Gitlab.config.gitlab.host
            uri.port = Gitlab.config.gitlab.port
          end
        end

        def query_params_for(page)
          if page && !page.empty?
            request.params.merge(REQUEST_PARAM => page.last_value)
          else
            request.params.except(REQUEST_PARAM)
          end
        end

        def page_href(page = nil)
          base_request_uri.tap do |uri|
            uri.query = query_params_for(page).to_query
          end.to_s
        end
      end
    end
  end
end
