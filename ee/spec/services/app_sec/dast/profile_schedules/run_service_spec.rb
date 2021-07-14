# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::ProfileSchedules::RunService do
  let_it_be(:schedule) { create(:dast_profile_schedule) }

  let(:run_service) { described_class.new }
  let(:create_service) { instance_double(::DastOnDemandScans::CreateService) }
  let(:service_result) { ServiceResponse.success }

  before do
    allow(::DastOnDemandScans::CreateService)
      .to receive(:new)
      .and_return(create_service)
    allow(create_service).to receive(:execute)
      .and_return(service_result)
    allow(Ability).to receive(:allowed?).and_return(true)
  end

  describe '#perform' do
    subject { run_service.perform }

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(dast_on_demand_scans_scheduler: false)
      end

      it 'does not call runnable_schedules' do
        expect(::Dast::ProfileSchedule).not_to receive(:runnable_schedules)
        subject
      end
    end

    context 'when multiple schedules exists' do
      before do
        schedule.update_column(:next_run_at, 1.minute.from_now)
      end

      def record_preloaded_queries
        recorder = ActiveRecord::QueryRecorder.new { subject }
        recorder.data.values.flat_map {|v| v[:occurrences]}.select do |query|
          ['FROM "projects"', 'FROM "users"', 'FROM "dast_profile"', 'FROM "dast_profile_schedule"'].any? do |s|
            query.include?(s)
          end
        end
      end

      it 'preloads configuration, project and owner to avoid N+1 queries' do
        expected_count = record_preloaded_queries.count

        travel_to(30.minutes.ago) { create_list(:dast_profile_schedule, 5) }
        actual_count = record_preloaded_queries.count

        expect(actual_count).to eq(expected_count)
      end
    end

    context 'when schedule exists' do
      let(:permission_error) { 'Insufficient Permissions' }

      before do
        schedule.update_column(:next_run_at, 10.minutes.ago)
      end

      it 'executes the rule schedule service' do
        expect_next_found_instance_of(::Dast::ProfileSchedule) do |schedule|
          expect(schedule).to receive(:schedule_next_run!)
        end

        expect(create_service).to receive(:execute)

        subject
      end

      context 'with deactivated owner' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          schedule.owner.deactivate!
          schedule.update_column(:next_run_at, 10.minutes.ago)
        end

        it 'logs the error' do
          expect(schedule.owner.deactivated?).to be true

          expect(Gitlab::AppLogger)
            .to receive(:info)
            .with(message: permission_error, schedule_id: schedule.id)

          subject
        end
      end

      context 'with no owner' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          schedule.update_columns(user_id: nil, next_run_at: 10.minutes.ago)
        end

        it 'logs the error' do
          expect(schedule.owner).to be nil
          expect(Gitlab::AppLogger)
            .to receive(:info)
            .with(message: permission_error, schedule_id: schedule.id)

          subject
        end
      end
    end

    context 'when create_service returns an error' do
      before do
        schedule.update_column(:next_run_at, 10.minutes.ago)
      end

      let(:error_message) { 'some message' }
      let(:service_result) { ServiceResponse.error(message: error_message) }

      it 'succeeds and logs the error' do
        expect(Gitlab::AppLogger)
          .to receive(:info)
          .with(message: error_message, schedule_id: schedule.id)

        subject
      end
    end

    context 'when schedule does not exist' do
      before do
        schedule.update_column(:next_run_at, 1.minute.from_now)
      end

      it 'executes the rule schedule service' do
        expect(::DastOnDemandScans::CreateService).not_to receive(:new)

        subject
      end
    end
  end
end
