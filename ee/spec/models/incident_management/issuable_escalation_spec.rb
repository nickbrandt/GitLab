# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalation do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }

  subject { build(:incident_management_issuable_escalation, issue: issue, policy: policy) }

  it { is_expected.to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:policy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:issue) }
    it { is_expected.to validate_presence_of(:policy) }
  end

  describe '.before_create' do
    describe '#set_last_notified_at' do
      let(:escalation) { build(:incident_management_issuable_escalation, issue: issue, policy: policy, last_notified_at: last_notified_at) }

      context 'when last_notified_at is not set' do
        let(:last_notified_at) { nil }

        it 'sets last_notified_at to current time' do
          expect { escalation.save! }.to change { escalation.last_notified_at }.to be_within(1.second).of Time.current
        end
      end

      context 'when last_notified_at is already set' do
        let(:last_notified_at) { 1.day.from_now }

        it 'does not change last_notified_at' do
          expect { escalation.save! }.not_to change { escalation.last_notified_at }
        end
      end
    end
  end
end
