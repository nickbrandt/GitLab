# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesInBatch do
  context 'when there is no more MigrateApproverToApprovalRules jobs' do
    let(:job) { double(:job) }

    it 'enables feature' do
      allow(Gitlab::BackgroundMigration::MigrateApproverToApprovalRules).to receive(:new).and_return(job)

      expect(job).to receive(:perform).exactly(3).times

      described_class.new.perform('Foo', [1, 2, 3])
    end
  end
end
