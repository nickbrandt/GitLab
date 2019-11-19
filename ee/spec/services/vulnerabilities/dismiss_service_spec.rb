# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::DismissService do
  include AccessMatchersGeneric

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }
  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let(:vulnerability) { create(:vulnerability, :with_findings, project: project) }
  let(:service) { described_class.new(user, vulnerability) }

  subject(:dismiss_vulnerability) { service.execute }

  context 'with an authorized user with proper permissions' do
    before do
      project.add_developer(user)
    end

    it 'dismisses a vulnerability and its associated findings' do
      Timecop.freeze do
        dismiss_vulnerability

        expect(vulnerability.reload).to(
          have_attributes(state: 'closed', closed_by: user, closed_at: be_like_time(Time.current)))
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
        expect(dismiss_vulnerability.errors.messages).to eq(
          base: ["failed to dismiss associated finding(id=#{broken_finding.id}): something went wrong"])
      end
    end

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'raises an "access denied" error' do
        expect { dismiss_vulnerability }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  describe 'permissions' do
    it { expect { dismiss_vulnerability }.to be_allowed_for(:admin) }
    it { expect { dismiss_vulnerability }.to be_allowed_for(:owner).of(project) }
    it { expect { dismiss_vulnerability }.to be_allowed_for(:maintainer).of(project) }
    it { expect { dismiss_vulnerability }.to be_allowed_for(:developer).of(project) }

    it { expect { dismiss_vulnerability }.to be_denied_for(:auditor) }
    it { expect { dismiss_vulnerability }.to be_denied_for(:reporter).of(project) }
    it { expect { dismiss_vulnerability }.to be_denied_for(:guest).of(project) }
    it { expect { dismiss_vulnerability }.to be_denied_for(:anonymous) }
  end
end
