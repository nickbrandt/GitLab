# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::ProfileSchedule, type: :model do
  describe '.runnable_schedules' do
    subject { described_class.runnable_schedules }

    context 'when there are runnable schedules' do
      let!(:profile_schedule) do
        travel_to(1.day.ago) do
          create(:dast_profile_schedule)
        end
      end

      it 'returns the runnable schedule' do
        is_expected.to eq([profile_schedule])
      end
    end

    context 'when there are inactive schedules' do
      let!(:profile_schedule) do
        travel_to(1.day.ago) do
          create(:dast_profile_schedule, active: false)
        end
      end

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end

    context 'when there are no runnable schedules' do
      let!(:profile_schedule) { }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end

    context 'when there are runnable schedules in future' do
      let!(:profile_schedule) do
        travel_to(1.day.from_now) do
          create(:dast_profile_schedule)
        end
      end

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '#set_next_run_at' do
    it_behaves_like 'handles set_next_run_at' do
      let(:schedule) { create(:dast_profile_schedule, cron: '*/1 * * * *') }
      let(:schedule_1) { create(:dast_profile_schedule) }
      let(:schedule_2) { create(:dast_profile_schedule) }
      let(:new_cron) { '0 0 1 1 *' }

      let(:ideal_next_run_at) { schedule.send(:ideal_next_run_from, Time.zone.now) }
      let(:cron_worker_next_run_at) { schedule.send(:cron_worker_next_run_from, Time.zone.now) }
    end
  end
end
