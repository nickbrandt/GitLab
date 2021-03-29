# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserCallout do
  let_it_be(:callout) { create(:user_callout, dismissed_at: 1.year.ago) }

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }

    it { is_expected.to validate_presence_of(:feature_name) }
    it { is_expected.to validate_uniqueness_of(:feature_name).scoped_to([:user_id, :callout_scope]).ignoring_case_sensitivity.with_message('has already been dismissed by this user for the same scope') }

    it { is_expected.to validate_exclusion_of(:callout_scope).in_array([nil]).with_message('cannot be nil') }
  end

  describe '#dismissed_after?' do
    let(:some_feature_name) { described_class.feature_names.keys.second }
    let(:callout_dismissed_month_ago) { create(:user_callout, feature_name: some_feature_name, dismissed_at: 1.month.ago )}
    let(:callout_dismissed_day_ago) { create(:user_callout, feature_name: some_feature_name, dismissed_at: 1.day.ago )}

    it 'returns whether a callout dismissed after specified date' do
      expect(callout_dismissed_month_ago.dismissed_after?(15.days.ago)).to eq(false)
      expect(callout_dismissed_day_ago.dismissed_after?(15.days.ago)).to eq(true)
    end
  end
end
