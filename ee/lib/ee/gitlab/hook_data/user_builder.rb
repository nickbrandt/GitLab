# frozen_string_literal: true
module EE
  module Gitlab
    module HookData
      module UserBuilder
        extend ::Gitlab::Utils::Override

        private

        override :user_data
        def user_data
          super.tap do |data|
            data.merge!(email_opted_in_data) if ::Gitlab.com?
          end
        end

        def email_opted_in_data
        {
          email_opted_in: user.email_opted_in,
          email_opted_in_ip: user.email_opted_in_ip,
          email_opted_in_source: user.email_opted_in_source,
          email_opted_in_at: user.email_opted_in_at
        }
        end
      end
    end
  end
end
