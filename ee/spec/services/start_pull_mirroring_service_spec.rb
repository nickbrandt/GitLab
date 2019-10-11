# frozen_string_literal: true

require 'spec_helper'

describe StartPullMirroringService do
  let(:project) { create(:project) }
  let(:import_state) { create(:import_state, project: project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user) }

  context "when retried more than #{Gitlab::Mirror::MAX_RETRY} times" do
    before do
      import_state.update(retry_count: Gitlab::Mirror::MAX_RETRY + 1)
    end

    it 'does not start pull mirroring' do
      expect(UpdateAllMirrorsWorker).not_to receive(:perform_async)
      expect(subject.execute[:status]).to eq(:error)
    end
  end

  context 'when does not reach the max retry limit yet' do
    before do
      import_state.update(retry_count: Gitlab::Mirror::MAX_RETRY - 1)
    end

    it 'starts pull mirroring' do
      expect(UpdateAllMirrorsWorker).to receive(:perform_async).once
      expect(import_state.reload.retry_count).not_to eq(0)
      expect(subject.execute[:status]).to eq(:success)
    end
  end
end
