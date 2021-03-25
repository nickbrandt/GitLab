# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::RefreshGroupsCounterWorker do
  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:root_group) { create(:group, parent: parent_group) }
    let_it_be(:subgroup) { create(:group, parent: root_group) }

    let(:count_service) { Groups::OpenIssuesCountService }
    let(:type) { 'issue' }
    let(:group_ids) { [root_group.id] }

    shared_examples 'a worker that takes no action' do
      it 'does not call count service or rise error' do
        expect(count_service).not_to receive(:new)
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        described_class.new.perform(type, user.id, group_ids)
      end
    end

    it 'anticipates the inability to find the issue' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception)
        .with(ActiveRecord::RecordNotFound, include(user_id: -1))
      expect(count_service).not_to receive(:new)

      described_class.new.perform(type, -1, group_ids)
    end

    context 'when group_ids is empty' do
      let(:group_ids) { [] }

      it_behaves_like 'a worker that takes no action'
    end

    context 'when type is not issue' do
      let(:type) { 'merge_request' }

      it_behaves_like 'a worker that takes no action'
    end

    context 'when updating cache' do
      let(:instance1) { instance_double(count_service) }
      let(:instance2) { instance_double(count_service) }

      context 'with existing cached value' do
        before do
          allow(instance1).to receive(:count_stored?).and_return(true)
          allow(instance2).to receive(:count_stored?).and_return(true)
        end

        it_behaves_like 'an idempotent worker' do
          let(:job_args) { [type, user.id, group_ids] }
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

      context 'with no cached value' do
        before do
          allow(instance1).to receive(:count_stored?).and_return(false)
          allow(instance2).to receive(:count_stored?).and_return(false)
        end

        it 'refreshes the issue count in given groups and ancestors' do
          expect(count_service).to receive(:new).with(root_group, user).and_return(instance1)
          expect(count_service).to receive(:new).with(parent_group, user).and_return(instance2)

          [instance1, instance2].all? {|i| expect(i).not_to receive(:refresh_cache_over_threshold) }

          described_class.new.perform(type, user.id, group_ids)
        end
      end
    end
  end
end
