# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesInBatch do
  context 'when there is no more MigrateApproverToApprovalRules jobs' do
    let(:job) { double(:job) }

    it 'migrates individual target' do
      allow(Gitlab::BackgroundMigration::MigrateApproverToApprovalRules).to receive(:new).and_return(job)

      expect(job).to receive(:perform).exactly(3).times

      described_class.new.perform('Foo', [1, 2, 3])
    end

    context 'when targets are projects' do
      let(:projects) { create_list(:project, 3) }

      context 'when projects contain merge requests' do
        it 'schedules migrations for merge requests' do
          merge_requests = projects.flat_map do |project|
            create(:merge_request, source_project: project, target_project: project)
          end

          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([[described_class.name, ["MergeRequest", merge_requests.map(&:id)]]])

          described_class.new.perform('Project', projects.map(&:id))
        end
      end

      context 'when merge request do not exist' do
        it 'does nothing' do
          expect(BackgroundMigrationWorker).not_to receive(:bulk_perform_async)

          described_class.new.perform('Project', projects.map(&:id))
        end
      end
    end
  end
end
