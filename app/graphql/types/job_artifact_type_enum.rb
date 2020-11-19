# frozen_string_literal: true

module Types
  class JobArtifactTypeEnum < BaseEnum
    ::Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.each do |key, value|
      value key.upcase, value: value, description: '...'
    end
  end
end
