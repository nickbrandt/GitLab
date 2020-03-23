# frozen_string_literal: true

module EE
  module API
    module Entities
      module GroupDetail
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
          expose :extra_shared_runners_minutes_limit
        end
      end
    end
  end
end
