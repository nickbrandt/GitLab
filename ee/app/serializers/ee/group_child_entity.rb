# frozen_string_literal: true

module EE
  module GroupChildEntity
    extend ActiveSupport::Concern

    prepended do
      # Project only attributes
      expose :marked_for_deletion_at,
        if: lambda { |_instance, _options| project? }
    end
  end
end
