# frozen_string_literal: true

module AppSec
  module Dast
    module ProfileSchedules
      class RunService
        def perform
          return unless Feature.enabled?(:dast_on_demand_scans_scheduler, default_enabled: :yaml)

          dast_runnable_schedules.find_in_batches do |schedules|
            schedules.each do |schedule|
              Gitlab::ApplicationContext.with_context(project: schedule.project, user: schedule.owner) do
                schedule.schedule_next_run!

                response = service(schedule).execute

                if response.error?
                  Gitlab::AppLogger.info(
                    message: response.message,
                    schedule_id: schedule.id
                  )
                end
              end
            end
          end
        end

        private

        def dast_runnable_schedules
          ::Dast::ProfileSchedule.with_project.with_profile.with_owner.runnable_schedules
        end

        def service(schedule)
          ::DastOnDemandScans::CreateService.new(
            container: schedule.project,
            current_user: schedule.owner,
            params: {
              dast_site_profile: schedule.dast_profile.dast_site_profile,
              dast_scanner_profile: schedule.dast_profile.dast_scanner_profile
            }
          )
        end
      end
    end
  end
end
