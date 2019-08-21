# frozen_string_literal: true

module Mutations
  module DesignManagement
    class Base < ::Mutations::BaseMutation
      include Mutations::ResolvesProject

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: "The project where the issue is to upload designs for"

      argument :iid, GraphQL::ID_TYPE,
               required: true,
               description: "The iid of the issue to modify designs for"

      private

      def find_object(project_path:, iid:)
        project = resolve_project(full_path: project_path)

        Resolvers::IssuesResolver.single.new(object: project, context: context)
          .resolve(iid: iid)
      end
    end
  end
end
