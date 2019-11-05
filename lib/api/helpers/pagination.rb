# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(relation)
        if params[:pagination] == "keyset"
          request_context = Gitlab::Pagination::Keyset::RequestContext.new(self)
          Gitlab::Pagination::Keyset.paginate(request_context, relation)
        else
          Gitlab::Pagination::OffsetPagination.new(self).paginate(relation)
        end
      end
    end
  end
end
