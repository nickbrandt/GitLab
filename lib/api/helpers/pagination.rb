# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(relation)
        if params[:pagination] == "keyset" && Feature.enabled?(:api_keyset_pagination)
          request_context = Gitlab::Pagination::Keyset::RequestContext.new(self)

          unless Gitlab::Pagination::Keyset.available?(request_context, relation)
            return error!('Keyset pagination is not yet available for this type of request', 501)
          end

          Gitlab::Pagination::Keyset.paginate(request_context, relation)
        else
          Gitlab::Pagination::OffsetPagination.new(self).paginate(relation)
        end
      end
    end
  end
end
