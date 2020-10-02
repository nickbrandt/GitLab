# frozen_string_literal: true

module Elastic
  module Latest
    class QueryContext
      module Aware
        def context
          @context ||= QueryContext.new
        end
      end

      def build_name(*args)
        ::Gitlab::Elastic::ExprName
          .new(self)
          .build(*current, *args)
      end

      def name(*args, &block)
        name = build_name(*args)

        return name.to_s unless block_given?

        begin
          contexts.push(name)
          yield name.to_s
        ensure
          contexts.pop
        end
      end

      def current
        return if contexts.empty?

        contexts.last
      end

      private

      def contexts
        @contexts ||= []
      end
    end
  end
end
