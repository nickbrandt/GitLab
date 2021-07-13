# frozen_string_literal: true

module AppSec
  module Dast
    class ProfileScheduleWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      # The ApplicationContext is declared in RunService because the metadata \
      # is not present here for the context.
      # rubocop:disable Scalability/CronWorkerContext
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :dynamic_application_security_testing

      def perform
        service.perform
      end

      private

      def service
        AppSec::Dast::ProfileSchedules::RunService.new
      end
    end
  end
end
