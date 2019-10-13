# frozen_string_literal: true

module Gitlab
  class ItemsCollection
    include Enumerable

    def initialize(items)
      @collection = items
    end

    def each
      collection.each { |item| yield item }
    end

    def page(number)
      Kaminari.paginate_array(collection).page(number)
    end

    def to_ary
      collection
    end

    private

    attr_reader :collection
  end
end
