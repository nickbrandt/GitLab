# frozen_string_literal: true

module Mutations
  module Ci
    class PipelineCancel < BaseMutation
      graphql_name 'PipelineCancel'

      authorize :update_pipeline

      def resolve
        ::Ci::CancelUserPipelinesService.new.execute(current_user)

        {
          errors: []
        }
      end

    end
  end
end
