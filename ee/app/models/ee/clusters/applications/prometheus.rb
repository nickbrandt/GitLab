# frozen_string_literal: true

require 'securerandom'

module EE
  module Clusters
    module Applications
      module Prometheus
        extend ActiveSupport::Concern

        prepended do
          attr_encrypted :alert_manager_token,
            mode: :per_attribute_iv,
            key: Settings.attr_encrypted_db_key_base_truncated,
            algorithm: 'aes-256-gcm'

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

        def generate_alert_manager_token!
          unless alert_manager_token.present?
            update!(alert_manager_token: generate_token)
          end
        end

        private

        def generate_token
          SecureRandom.hex
        end
      end
    end
  end
end
