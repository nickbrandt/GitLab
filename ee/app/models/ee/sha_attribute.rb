# frozen_string_literal: true

module EE
  module ShaAttribute
    def validate_binary_column_exists!(name)
      super
    rescue Geo::TrackingBase::SecondaryNotConfigured
    end
  end
end
