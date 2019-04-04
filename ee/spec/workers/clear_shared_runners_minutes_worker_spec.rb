require 'spec_helper'

describe ClearSharedRunnersMinutesWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      expect_any_instance_of(described_class)
        .to receive(:try_obtain_lease).and_return(true)
    end

    subject { worker.perform }

    context 'when project statistics are defined' do
      let(:project) { create(:project) }
      let(:statistics) { project.statistics }

      before do
        statistics.update(shared_runners_seconds: 100)
      end

      it 'clears counters' do
        subject

        expect(statistics.reload.shared_runners_seconds).to be_zero
      end

      it 'resets timer' do
        subject

        expect(statistics.reload.shared_runners_seconds_last_reset).to be_like_time(Time.now)
      end
    end

    context 'when namespace statistics are defined' do
      let!(:statistics) { create(:namespace_statistics, shared_runners_seconds: 100) }

      it 'clears counters' do
        subject

        expect(statistics.reload.shared_runners_seconds).to be_zero
      end

      it 'resets timer' do
        subject

        expect(statistics.reload.shared_runners_seconds_last_reset).to be_like_time(Time.now)
      end
    end

    context 'when namespace has extra shared runner minutes', :postgresql do
      let!(:namespace) do
        create(:namespace, shared_runners_minutes_limit: 100, extra_shared_runners_minutes_limit: 10 )
      end

      let!(:statistics) do
        create(:namespace_statistics, namespace: namespace, shared_runners_seconds: minutes_used * 60)
      end

      let(:minutes_used) { 0 }

      context 'when consumption is below the default quota' do
        let(:minutes_used) { 50 }

        it 'does not modify the extra minutes quota' do
          subject

          expect(namespace.reload.extra_shared_runners_minutes_limit).to eq(10)
        end
      end

      context 'when consumption is above the default quota' do
        context 'when all extra minutes are used' do
          let(:minutes_used) { 115 }

          it 'sets extra minutes to 0' do
            subject

            expect(namespace.reload.extra_shared_runners_minutes_limit).to eq(0)
          end
        end

        context 'when some extra minutes are used' do
          let(:minutes_used) { 105 }

          it 'it discounts the extra minutes used' do
            subject

            expect(namespace.reload.extra_shared_runners_minutes_limit).to eq(5)
          end
        end
      end
    end
  end
end
