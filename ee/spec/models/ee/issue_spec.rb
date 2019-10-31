# frozen_string_literal: true

require 'spec_helper'

describe Issue do
  describe '.in_epics' do
    let_it_be(:epic1) { create(:epic) }
    let_it_be(:epic2) { create(:epic) }
    let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1) }
    let_it_be(:epic_issue2) { create(:epic_issue, epic: epic2) }

    before do
      stub_licensed_features(epics: true)
    end

    it 'returns only issues in selected epics' do
      expect(described_class.count).to eq 2
      expect(described_class.in_epics([epic1])).to eq [epic_issue1.issue]
    end
  end
end
