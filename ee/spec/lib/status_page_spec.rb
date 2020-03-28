# frozen_string_literal: true

require 'spec_helper'

describe StatusPage do
  describe '.trigger_publish' do
    let(:project) { instance_double(Project) }
    let(:user) { instance_double(User) }
    let(:triggered_by) { instance_double(Issue) }

    subject { described_class.trigger_publish(project, user, triggered_by) }

    it 'delegates to TriggerPublishService' do
      expect_next_instance_of(StatusPage::TriggerPublishService,
                              project, user, triggered_by) do |service|
        expect(service).to receive(:execute)
      end

      subject
    end
  end
end
