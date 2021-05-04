# frozen_string_literal: true

module EE
  module Types
    module Ci
      module CiCdSettingType
        extend ActiveSupport::Concern

        prepended do
          field :allow_merge_before_pipeline_completes, GraphQL::BOOLEAN_TYPE, null: false,
            description: "Whether to allow merging (via API or 'merge immediately' button) before a pipeline completes.",
            method: :allow_merge_before_pipeline_completes?
        end
      end
    end
  end
end
