# frozen_string_literal: true

module Mutations
  module Epics
    class Base < ::Mutations::BaseMutation
      include Mutations::ResolvesGroup

      private

      def find_object(group_path:, iid:)
        group = resolve_group(full_path: group_path)
        resolver = Resolvers::EpicResolver
                     .single.new(object: group, context: context)

        resolver.resolve(iid: iid)
      end
    end
  end
end
