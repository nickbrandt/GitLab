# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      def self.paginate(request_context, relation)
        Gitlab::Pagination::Keyset::Pager.new(request_context).paginate(relation)
      end
    end
  end
end
