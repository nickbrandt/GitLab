# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::DismissService do
  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }
  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let(:vulnerability) { create(:vulnerability, :with_findings, project: project) }
  let(:service) { described_class.new(user, vulnerability) }

  subject { service.execute }

  context 'with an authorized user with proper permissions' do
    before do
      project.add_developer(user)
    end

    it 'dismisses a vulnerability and its associated findings' do
      Timecop.freeze do
        subject

        expect(vulnerability.reload).to(
          have_attributes(state: 'closed', closed_by: user, closed_at: be_like_time(Time.zone.now)))
        expect(vulnerability.findings).to all have_vulnerability_dismissal_feedback
      end
    end

    context 'when there is a finding dismissal error' do
      before do
        allow(service).to receive(:dismiss_findings).and_return(
          described_class::FindingsDismissResult.new(false, broken_finding, 'something went wrong'))
      end

      let(:broken_finding) { vulnerability.findings.first }

      it 'responds with error' do
        expect(subject.errors.messages).to eq(
          base: ["failed to dismiss associated finding(id=#{broken_finding.id}): something went wrong"])
      end
    end

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'raises an "access denied" error' do
        expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  context 'when user does not have rights to dismiss a vulnerability' do
    before do
      project.add_reporter(user)
    end

    it 'raises an "access denied" error' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
