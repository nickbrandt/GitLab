# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(relation)
        return paginate_with_offset(relation) unless keyset_pagination_enabled?

        paginate_with_key(relation)
      end

      private

      def paginate_with_offset(relation)
        Gitlab::Pagination::OffsetPagination.new(self).paginate(relation)
      end

      def paginate_with_key(relation)
        request_context = Gitlab::Pagination::Keyset::RequestContext.new(self)

        unless Gitlab::Pagination::Keyset.available?(request_context, relation)
          return error!('Keyset pagination is not yet available for this type of request', 405)
        end

        Gitlab::Pagination::Keyset.paginate(request_context, relation)
      end

      def keyset_pagination_enabled?
        params[:pagination] == 'keyset' && Feature.enabled?(:api_keyset_pagination, default_enabled: true)
      end
    end
  end
end
