# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssueEscalationStatus do
  let_it_be(:issue) { create(:issue) }

  subject { build(:incident_management_issue_escalation_status, issue: issue) }

  it { is_expected.to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validatons' do
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:issue) }
    it { is_expected.to validate_presence_of(:status) }

    describe 'status' do
      let_it_be(:escalatable_factory) { :incident_management_issue_escalation_status }

      it_behaves_like 'an Escalatable model'
    end
  end

  context 'escalation policy changes' do
    shared_examples 'unresolves the status when the policy is changed' do
      let_it_be(:new_policy) { create(:incident_management_escalation_policy) }

      context 'when already triggered' do
        it 'has no impact' do
          expect { issue_status.update!(policy: new_policy) }
            .to not_change(issue_status, :status)
            .and not_change(issue_status, :resolved_at)
        end
      end

      context 'when resolved' do
        before do
          issue_status.resolve
        end

        it 're-triggers the issue escalation status' do
          expect(issue_status).to be_resolved
          expect(issue_status.resolved_at).to be_present

          issue_status.update!(policy: new_policy)

          expect(issue_status).to be_triggered
          expect(issue_status.resolved_at).to be_nil
        end
      end
    end

    context 'without escalation policy' do
      let_it_be(:issue_status, reload: true) { create(:incident_management_issue_escalation_status, issue: issue) }

      it_behaves_like 'unresolves the status when the policy is changed'
    end

    context 'with escalation policy' do
      let_it_be(:issue_status, reload: true) { create(:incident_management_issue_escalation_status, :paging, issue: issue) }

      it_behaves_like 'unresolves the status when the policy is changed'
    end
  end
end
