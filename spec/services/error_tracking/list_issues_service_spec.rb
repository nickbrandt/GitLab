# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::ListIssuesService do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:client) { Sentry::Client.new(sentry_url, token) }

  let(:error_tracking_setting) do
    create(:project_error_tracking_setting, api_url: sentry_url, token: token, project: project)
  end

  subject { described_class.new(project, user) }

  before do
    expect(project).to receive(:error_tracking_setting).at_least(:once).and_return(error_tracking_setting)

    project.add_reporter(user)
  end

  describe '#execute' do
    context 'with authorized user' do
      before do
        expect(error_tracking_setting).to receive(:sentry_client).and_return(client)
      end

      it 'calls sentry client' do
        expect(client).to receive(:list_issues).and_return([])

        result = subject.execute

        expect(result).to include(status: :success)
      end
    end

    context 'with unauthorized user' do
      let(:unauthorized_user) { create(:user) }

      subject { described_class.new(project, unauthorized_user) }

      it 'returns error' do
        result = subject.execute

        expect(result).to include(status: :error, message: 'access denied')
      end
    end

    context 'with error tracking disabled' do
      before do
        error_tracking_setting.enabled = false
      end

      it 'raises error' do
        result = subject.execute

        expect(result).to include(status: :error, message: 'not enabled')
      end
    end
  end

  describe '#sentry_external_url' do
    let(:external_url) { 'https://sentrytest.gitlab.com/sentry-org/sentry-project' }

    it 'calls ErrorTracking::ProjectErrorTrackingSetting' do
      expect(error_tracking_setting).to receive(:sentry_external_url).and_call_original

      subject.external_url
    end
  end
end
