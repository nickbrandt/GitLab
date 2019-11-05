# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class Page
        DEFAULT_PAGE_SIZE = 20

        attr_reader :last_value, :column

        def initialize(last_value, column: :id, per_page: DEFAULT_PAGE_SIZE, is_first_page: false)
          @last_value = last_value
          @column = column
          @per_page = per_page || DEFAULT_PAGE_SIZE
          @is_first_page = is_first_page
        end

        def per_page
          return DEFAULT_PAGE_SIZE if @per_page <= 0

          [@per_page, DEFAULT_PAGE_SIZE].min
        end

        def empty?
          last_value.nil? && !first_page?
        end

        def first_page?
          @is_first_page
        end
      end
    end
  end
end
