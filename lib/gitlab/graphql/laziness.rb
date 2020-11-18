# frozen_string_literal: true

module Gitlab
  module Graphql
    # This module allows your class to easily defer and force values.
    # Its methods are just sugar for calls to the Gitlab::Graphql::Lazy class.
    #
    # example:
    #
    #  class MyAwesomeClass
    #    def sum_frobbocities(ids)
    #      ids.map { |n| get_the_thing(n) }.map(&method(:force).sum
    #    end
    #
    #    def get_the_thing(id)
    #      thunk = SomeBatchLoader.load(id)
    #      defer { force(thunk).frobbocity * 2 }
    #    end
    #  end
    #
    # In the example above, we use defer to delay forcing the batch-loaded
    # item until we need it, and then we use `force` to consume the lazy values
    #
    # If `SomeBatchLoader.load(id)` batches correctly, calling
    # `sum_frobbocities` will only perform one batched load.
    #
    module Laziness
      def defer(&block)
        ::Gitlab::Graphql::Lazy.new(&block)
      end

      def force(lazy)
        ::Gitlab::Graphql::Lazy.force(lazy)
      end
    end
  end
end
