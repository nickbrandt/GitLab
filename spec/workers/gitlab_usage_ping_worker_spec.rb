# frozen_string_literal: true

require 'spec_helper'

describe GitlabUsagePingWorker do
  subject { described_class.new }

  it 'delegates to SubmitUsagePingService' do
    allow(subject).to receive(:try_obtain_lease).and_return(true)

    expect(Gitlab::GrafanaEmbedUsageData).to receive(:write_issue_count)
    expect_any_instance_of(SubmitUsagePingService).to receive(:execute)

    subject.perform
  end
end
