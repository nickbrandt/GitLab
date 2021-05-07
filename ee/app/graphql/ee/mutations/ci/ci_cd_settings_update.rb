# frozen_string_literal: true

module EE
  module Mutations
    module Ci
      module CiCdSettingsUpdate
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :merge_pipelines_enabled, GraphQL::BOOLEAN_TYPE,
            required: false,
            description: 'Indicates if merge pipelines are enabled for the project.'

          argument :merge_trains_enabled, GraphQL::BOOLEAN_TYPE,
            required: false,
            description: 'Indicates if merge trains are enabled for the project.'

          argument :merge_before_pipeline_completes_enabled, GraphQL::BOOLEAN_TYPE,
            required: false,
            description: "Indicates if merging (via API or 'merge immediately' button) is allowed before a pipeline completes."
        end
      end
    end
  end
end
