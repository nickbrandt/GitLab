# frozen_string_literal: true

module EE
  module Clusters
    module Concerns
      module ApplicationCore
        extend ActiveSupport::Concern

        prepended do
          include UsageStatistics

          class_methods do
            def distinct_by_user
              available.joins(:cluster).distinct_count_by(:user_id)
            end
          end
        end
      end
    end
  end
end
