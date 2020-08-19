# frozen_string_literal: true

module Mutations
  module Ci
    class Base < BaseMutation

      argument :id, GraphQL::ID_TYPE,
                required: true,
                description: 'The id of the pipeline to mutate'

      field :pipeline,
            Types::Ci::PipelineType,
            null: true,
            description: 'The pipeline after mutation'

      private

      def find_object(id:)
        ::Ci::Pipeline.find(id)
      end
    end
  end
end
