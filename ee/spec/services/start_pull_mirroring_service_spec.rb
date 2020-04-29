# frozen_string_literal: true

require 'spec_helper'

describe StartPullMirroringService do
  let(:project) { create(:project) }
  let(:import_state) { create(:import_state, project: project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, pause_on_hard_failure: pause_on_hard_failure) }

  shared_examples_for 'retry count did not reset' do
    it 'does not reset import state retry_count' do
      expect { execute }.not_to change { import_state.retry_count }
    end
  end

  shared_examples_for 'pull mirroring has started' do
    shared_examples_for 'force mirror update' do
      it 'enqueues UpdateAllMirrorsWorker' do
        Sidekiq::Testing.fake! do
          expect { execute }
            .to change { UpdateAllMirrorsWorker.jobs.size }
            .by(1)
          expect(execute[:status]).to eq(:success)
        end
      end
    end

    it_behaves_like 'force mirror update'

    context 'when project mirror has been updated in the last 5 minutes' do
      it 'schedules next execution' do
        Timecop.freeze(Time.current) do
          import_state.update(last_update_at: 3.minutes.ago)

          expect { execute }
            .to change { import_state.next_execution_timestamp }
            .to(2.minutes.from_now)
            .and not_change { UpdateAllMirrorsWorker.jobs.size }
        end
      end
    end

    context 'when project mirror has been updated more than 5 minutes ago' do
      before do
        import_state.update(last_update_at: 6.minutes.ago)
      end

      it_behaves_like 'force mirror update'
    end
  end

  context 'when pause_on_hard_failure is false' do
    let(:pause_on_hard_failure) { false }

    context "when retried more than #{Gitlab::Mirror::MAX_RETRY} times" do
      before do
        import_state.update(retry_count: Gitlab::Mirror::MAX_RETRY + 1)
      end

      it_behaves_like 'pull mirroring has started'

      it 'resets the import state retry_count' do
        expect { execute }.to change { import_state.retry_count }.to(0)
      end
    end

    context 'when does not reach the max retry limit yet' do
      before do
        import_state.update(retry_count: Gitlab::Mirror::MAX_RETRY - 1)
      end

      it_behaves_like 'pull mirroring has started'
      it_behaves_like 'retry count did not reset'
    end
  end

  context 'when pause_on_hard_failure is true' do
    let(:pause_on_hard_failure) { true }

    context "when retried more than #{Gitlab::Mirror::MAX_RETRY} times" do
      before do
        import_state.update(retry_count: Gitlab::Mirror::MAX_RETRY + 1)
      end

      it_behaves_like 'retry count did not reset'

      it 'does not start pull mirroring' do
        expect { execute }.to not_change { UpdateAllMirrorsWorker.jobs.size }
        expect(execute[:status]).to eq(:error)
      end
    end

    context 'when does not reach the max retry limit yet' do
      before do
        import_state.update(retry_count: Gitlab::Mirror::MAX_RETRY - 1)
      end

      it_behaves_like 'pull mirroring has started'
      it_behaves_like 'retry count did not reset'
    end
  end

  def execute
    subject.execute
  end
end
