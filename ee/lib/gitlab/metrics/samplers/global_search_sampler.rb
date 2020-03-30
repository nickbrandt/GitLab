# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class GlobalSearchSampler < BaseSampler
        def sample
          ::Elastic::MetricsUpdateService.new.execute
        end
      end
    end
  end
end
