# frozen_string_literal: true

module EE
  module Mutations
    module Issues
      module Update
        extend ActiveSupport::Concern

        prepended do
          argument :health_status,
                   ::Types::HealthStatusEnum,
                   required: false,
                   description: 'The desired health status'
        end
      end
    end
  end
end
