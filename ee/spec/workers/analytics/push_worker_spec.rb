# frozen_string_literal: true

require 'spec_helper'

describe Analytics::PushWorker do
  describe '#perform' do
    before do
      stub_licensed_features(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => true)
    end

    context 'when project cannot be found' do
      it 'does not trigger CommitWorker' do
        expect(Analytics::CodeAnalytics::CommitWorker).not_to receive(:perform_async)

        described_class.new.perform(-1, 'does_not_matter', 'does_not_matter')
      end
    end

    context 'when feature is not available' do
      let(:project) { create(:project) }

      before do
        stub_licensed_features(Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG => false)
      end

      it 'does not trigger CommitWorker' do
        expect(Analytics::CodeAnalytics::CommitWorker).not_to receive(:perform_async)

        described_class.new.perform(project.id, 'does_not_matter', 'does_not_matter')
      end
    end

    it 'triggers CommitWorker for each commit between old and new commits' do
      project = create(:project, :repository)
      new, middle, old = project.repository.commits(nil, limit: 3)

      expect(Analytics::CodeAnalytics::CommitWorker).to receive(:perform_async).with(project.id, middle.sha)
      expect(Analytics::CodeAnalytics::CommitWorker).to receive(:perform_async).with(project.id, new.sha)

      described_class.new.perform(project.id, old.sha, new.sha)
    end
  end
end
