# frozen_string_literal: true

module EE
  module Types
    module Ci
      module CiCdSettingType
        extend ActiveSupport::Concern

        prepended do
          field :merge_before_pipeline_completes_available, GraphQL::BOOLEAN_TYPE, null: false,
            description: "Whether merging before pipelines complete is allowed (via API or 'merge immediately' button).",
            method: :merge_before_pipeline_completes_available?
        end
      end
    end
  end
end
