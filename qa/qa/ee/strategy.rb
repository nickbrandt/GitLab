# frozen_string_literal: true

module QA
  module EE
    module Strategy
      extend self

      def extend_autoloads!
        require 'qa/ee'
      end

      def perform_before_hooks
        return unless ENV['EE_LICENSE']

        QA::Support::Retrier.retry_on_exception do
          QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login) do
            EE::Resource::License.fabricate!(ENV['EE_LICENSE'])
          end
        end
      end
    end
  end
end
