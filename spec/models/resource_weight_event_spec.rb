# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceWeightEvent, type: :model do
  describe 'validations' do
    it { is_expected.not_to allow_value(nil).for(:user) }
    it { is_expected.not_to allow_value(nil).for(:issue) }
    it { is_expected.to allow_value(nil).for(:weight) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:issue) }
  end

  describe '.by_issue' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    let_it_be(:issue1) { create(:issue, author: user1) }
    let_it_be(:issue2) { create(:issue, author: user1) }
    let_it_be(:issue3) { create(:issue, author: user2) }

    let_it_be(:event1) { create(:resource_weight_event, issue: issue1) }
    let_it_be(:event2) { create(:resource_weight_event, issue: issue2) }
    let_it_be(:event3) { create(:resource_weight_event, issue: issue1) }

    it 'returns the expected records for an issue with events' do
      events = ResourceWeightEvent.by_issue(issue1)

      expect(events).to contain_exactly(event1, event3)
    end

    it 'returns the expected records for an issue with no events' do
      events = ResourceWeightEvent.by_issue(issue3)

      expect(events).to be_empty
    end
  end
end
