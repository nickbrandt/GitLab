# frozen_string_literal: true

module Gitlab
  class DependenciesCollection
    include Enumerable

    def initialize(dependencies)
      @collection = dependencies
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
