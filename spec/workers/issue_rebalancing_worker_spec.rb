# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueRebalancingWorker do
  describe '#perform' do
    it 'runs an instance of IssueRebalancingService' do
      issue = create(:issue)

      service = double(execute: nil)
      expect(IssueRebalancingService).to receive(:new).with(issue).and_return(service)

      described_class.new.perform(issue.id)
    end
  end
end
