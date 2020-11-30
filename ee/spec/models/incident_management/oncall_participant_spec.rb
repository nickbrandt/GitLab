# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallParticipant do
  let_it_be(:rotation) { create(:incident_management_oncall_rotation) }

  describe '.associations' do
    it { is_expected.to belong_to(:oncall_rotation) }
    it { is_expected.to belong_to(:participant) }
  end

  describe '.validations' do
    let(:timezones) { ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.identifier } }
    let(:user) { create(:user) }

    subject { build(:incident_management_oncall_participant, oncall_rotation: rotation, user: user) }

    it { is_expected.to validate_presence_of(:oncall_rotation) }
    it { is_expected.to validate_length_of(:participant) }

    context 'when the participant already exists in the rotation' do
      before do
        create(:incident_management_oncall_participant, oncall_rotation: rotation, user: user)
      end

      it 'has validation errors' do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages.to_sentence).to eq('Participant has already been taken')
      end
    end
  end
end
