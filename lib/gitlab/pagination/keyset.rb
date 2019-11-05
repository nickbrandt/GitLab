# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      def self.paginate(request_context, relation)
        paged_relation = Gitlab::Pagination::Keyset::Pager.new(request_context).paginate(relation)

        request_context.apply_headers(paged_relation)

        paged_relation.relation
      end
    end
  end
end
