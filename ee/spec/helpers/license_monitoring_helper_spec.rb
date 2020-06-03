# frozen_string_literal: true

require 'spec_helper'

describe LicenseMonitoringHelper do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:license_seats_limit) { 10 }

  let_it_be(:license) do
    create(:license, data: build(:gitlab_license, restrictions: { active_user_count: license_seats_limit }).export)
  end

  describe '#show_users_over_license_banner?' do
    subject { helper.show_users_over_license_banner? }

    before do
      create(:historical_data, date: license.created_at + 1.month, active_user_count: active_user_count)
    end

    context 'when admin is logged in' do
      before do
        allow(helper).to receive(:current_user).and_return(admin)
      end

      context 'when license is above the threshold' do
        let(:active_user_count) { license_seats_limit + 5 }

        it { is_expected.to eq(true) }
      end

      context 'when license is below the threshold' do
        let(:active_user_count) { 1 }

        it { is_expected.to eq(false) }
      end
    end

    context 'when regular user is logged in' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'when license is above the threshold' do
        let(:active_user_count) { license_seats_limit + 5 }

        it { is_expected.to eq(false) }
      end

      context 'when license is below the threshold' do
        let(:active_user_count) { 1 }

        it { is_expected.to eq(false) }
      end
    end

    context 'with anonymous user' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      context 'when license is above the threshold' do
        let(:active_user_count) { license_seats_limit + 5 }

        it { is_expected.to be_falsey }
      end

      context 'when license is below the threshold' do
        let(:active_user_count) { 1 }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#show_active_user_count_threshold_banner?' do
    let_it_be(:current_active_users_count) { 1 }

    subject { helper.show_active_user_count_threshold_banner? }

    before do
      allow(helper).to receive(:current_active_users_count).and_return(current_active_users_count)
    end

    context 'when admin user is logged in' do
      before do
        allow(helper).to receive(:current_user).and_return(admin)
      end

      context 'when active users count is above the threshold' do
        let(:current_active_users_count) { license_seats_limit - 1 }

        it { is_expected.to be_truthy }
      end

      context 'when active users count is below the threshold' do
        let(:current_active_users_count) { 1 }

        it { is_expected.to be_falsey }
      end
    end

    context 'when regular user is logged in' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'when active users count is above the threshold' do
        let(:current_active_users_count) { license_seats_limit - 1 }

        it { is_expected.to be_falsey }
      end

      context 'when active users count is below the threshold' do
        let(:current_active_users_count) { 1 }

        it { is_expected.to be_falsey }
      end
    end

    context 'with anonymous user' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      context 'when active users count is above the threshold' do
        let(:current_active_users_count) { license_seats_limit - 1 }

        it { is_expected.to be_falsey }
      end

      context 'when active users count is below the threshold' do
        let(:current_active_users_count) { 1 }

        it { is_expected.to be_falsey }
      end
    end
  end
end
