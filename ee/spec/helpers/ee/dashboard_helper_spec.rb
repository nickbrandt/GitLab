# frozen_string_literal: true

require 'spec_helper'

describe DashboardHelper, type: :helper do
  include AnalyticsHelpers

  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#dashboard_nav_links' do
    context 'when at least one analytics feature is enabled' do
      before do
        enable_only_one_analytics_feature_flag
      end

      it 'includes analytics' do
        expect(helper.dashboard_nav_links).to include(:analytics)
      end
    end

    context 'when all analytics features are disabled' do
      before do
        disable_all_analytics_feature_flags
      end

      it 'does not include analytics' do
        expect(helper.dashboard_nav_links).not_to include(:analytics)
      end
    end
  end

  describe '.has_start_trial?' do
    using RSpec::Parameterized::TableSyntax

    where(:has_license, :current_user, :output) do
      false | :admin | true
      false | :user  | false
      true  | :admin | false
      true  | :user  | false
    end

    with_them do
      let(:user) { create(current_user) }
      let(:license) { has_license && create(:license) }
      subject { helper.has_start_trial? }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:current_license).and_return(license)
      end

      it { is_expected.to eq(output) }
    end
  end
end
