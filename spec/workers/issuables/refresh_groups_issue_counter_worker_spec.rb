# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::RefreshGroupsIssueCounterWorker do
  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:root_group) { create(:group, parent: parent_group) }
    let_it_be(:subgroup) { create(:group, parent: root_group) }

    let(:count_service) { Groups::OpenIssuesCountService }
    let(:group_ids) { [root_group.id] }

    it 'anticipates the inability to find the issue' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception)
        .with(ActiveRecord::RecordNotFound, include(user_id: -1))
      expect(count_service).not_to receive(:new)

      described_class.new.perform(-1, group_ids)
    end

    context 'when group_ids is empty' do
      let(:group_ids) { [] }

      it 'does not call count service or rise error' do
        expect(count_service).not_to receive(:new)
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        described_class.new.perform(user.id, group_ids)
      end
    end

    context 'when updating cache' do
      let(:instance1) { instance_double(count_service) }
      let(:instance2) { instance_double(count_service) }

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [user.id, group_ids] }
        let(:exec_times) { IdempotentWorkerHelper::WORKER_EXEC_TIMES }

        it 'refreshes the issue count in given groups and ancestors' do
          expect(count_service).to receive(:new)
            .exactly(exec_times).times.with(root_group, user).and_return(instance1)
          expect(count_service).to receive(:new)
            .exactly(exec_times).times.with(parent_group, user).and_return(instance2)
          expect(count_service).not_to receive(:new).with(subgroup, user)

          [instance1, instance2].all? do |instance|
            expect(instance).to receive(:refresh_cache_over_threshold).exactly(exec_times).times
          end

          subject
        end
      end
    end
  end
end
