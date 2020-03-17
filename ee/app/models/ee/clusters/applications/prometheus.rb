# frozen_string_literal: true

require 'securerandom'

module EE
  module Clusters
    module Applications
      module Prometheus
        extend ActiveSupport::Concern

        prepended do
          state_machine :status do
            after_transition any => :updating do |application|
              application.update(last_update_started_at: Time.now)
            end
          end
        end

        def updated_since?(timestamp)
          last_update_started_at &&
            last_update_started_at > timestamp &&
            !update_errored?
        end
      end
    end
  end
end
