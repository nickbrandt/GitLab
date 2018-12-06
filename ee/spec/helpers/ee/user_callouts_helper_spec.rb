# frozen_string_literal: true

require "spec_helper"

describe EE::UserCalloutsHelper do
  describe '.show_gold_trial?' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:user_dismissed?).with(EE::UserCalloutsHelper::GOLD_TRIAL).and_return(false)
      allow(Gitlab).to receive(:com?).and_return(true)
      allow(Gitlab::Database).to receive(:read_only?).and_return(false)
      allow(user).to receive(:any_namespace_with_gold?).and_return(false)
      allow(user).to receive(:any_namespace_with_trial?).and_return(false)
    end

    it 'returns true when all conditions are met' do
      expect(helper.show_gold_trial?(user)).to be(true)
    end

    it 'returns false when there is no user record' do
      allow(helper).to receive(:current_user).and_return(nil)

      expect(helper.show_gold_trial?).to be(false)
    end
  end
end
