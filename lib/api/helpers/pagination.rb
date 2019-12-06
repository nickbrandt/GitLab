# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(relation)
        ::Gitlab::Pagination::OffsetPagination.new(self).paginate(relation)
      end

      # This applies pagination and executes the query
      # It always returns an array instead of an ActiveRecord relation
      def paginate_and_retrieve!(relation)
        paginate(relation).to_a
      end
    end
  end
end
