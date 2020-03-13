# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::TriggerPublishService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let(:service) { described_class.new(user: user, project: project) }
  let(:worker) { StatusPage::PublishIncidentWorker }

  let_it_be(:status_page_setting) do
    create(:status_page_setting, :enabled, project: project)
  end

  subject { service.execute(issue.id) }

  shared_examples 'no job scheduled' do
    it 'does not schedule a job' do
      expect(worker).not_to receive(:perform_async)

      subject
    end
  end

  describe '#execute' do
    before do
      project.add_maintainer(user)
      stub_feature_flags(status_page: true)
      stub_licensed_features(status_page: true)

      allow(worker).to receive(:perform_async)
        .with(user.id, project.id, issue.id)
    end

    it 'schedules a job' do
      expect(worker).to receive(:perform_async)
        .with(user.id, project.id, issue.id)

      subject
    end

    context 'when status page is missing' do
      before do
        status_page_setting.destroy
      end

      include_examples 'no job scheduled'
    end

    context 'when status page is not enabled' do
      before do
        status_page_setting.update!(enabled: false)
      end

      include_examples 'no job scheduled'
    end

    context 'when license is not available' do
      before do
        stub_licensed_features(status_page: false)
      end

      include_examples 'no job scheduled'
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(status_page: false)
      end

      include_examples 'no job scheduled'
    end

    context 'when user cannot publish status page' do
      before do
        project.add_reporter(user)
      end

      include_examples 'no job scheduled'
    end
  end
end
