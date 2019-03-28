# frozen_string_literal: true

require 'spec_helper'

describe IssuablesHelper do
  describe '#issuable_initial_data' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
      stub_commonmark_sourcepos_disabled
    end

    it 'returns the correct data that includes canAdmin: true' do
      issue = create(:issue, author: user, description: 'issue text')
      @project = issue.project

      expect(helper.issuable_initial_data(issue)).to include(canAdmin: true)
    end
  end
end
