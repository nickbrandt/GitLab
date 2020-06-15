# frozen_string_literal: true

module EE
  module Ci
    module BuildMetadata
      extend ActiveSupport::Concern

      prepended do
        validates :secrets, json_schema: { filename: 'build_metadata_secrets' }
      end
    end
  end
end
